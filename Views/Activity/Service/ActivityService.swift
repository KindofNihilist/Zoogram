//
//  ActivityService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 19.05.2023.
//

import Foundation

protocol ActivityServiceProtocol {
    var activitySystemService: ActivitySystemProtocol { get }
    var followSystemService: FollowSystemProtocol { get }
    var userDataService: UserDataServiceProtocol { get }
    var userPostsService: UserPostsServiceProtocol { get }
    var storageManager: StorageManagerProtocol { get }

    func observeActivityEvents(completion: @escaping (Result<[ActivityEvent], Error>) -> Void)
    func updateActivityEventsSeenStatus(events: Set<ActivityEvent>, completion: @escaping (VoidResult) -> Void)
    func followSubscriberBack(uid: String, completion: @escaping (Result<FollowStatus, Error>) -> Void)
    func unfollowSubscriber(uid: String, completion: @escaping (Result<FollowStatus, Error>) -> Void)
}

class ActivityService: ImageService, ActivityServiceProtocol {
    let activitySystemService: ActivitySystemProtocol
    let followSystemService: FollowSystemProtocol
    let userDataService: UserDataServiceProtocol
    let userPostsService: UserPostsServiceProtocol
    let storageManager: StorageManagerProtocol

    init(activitySystemService: ActivitySystemProtocol,
         followSystemService: FollowSystemProtocol,
         userDataService: UserDataServiceProtocol,
         userPostsService: UserPostsServiceProtocol,
         storageManager: StorageManagerProtocol)
    {
        self.activitySystemService = activitySystemService
        self.followSystemService = followSystemService
        self.userDataService = userDataService
        self.userPostsService = userPostsService
        self.storageManager = storageManager
    }

    func observeActivityEvents(completion: @escaping (Result<[ActivityEvent], Error>) -> Void) {
        activitySystemService.observeActivityEvents { result in
            switch result {
            case .success(let events):
                self.getAdditionalDataFor(events: events) { result in
                    completion(result)
                }
            case .failure(let error):
                completion(.failure(error))
            }

        }
    }

    func updateActivityEventsSeenStatus(events: Set<ActivityEvent>, completion: @escaping (VoidResult) -> Void) {
        activitySystemService.updateActivityEventsSeenStatus(events: events) { result in
            completion(result)
        }
    }

    func followSubscriberBack(uid: String, completion: @escaping (Result<FollowStatus, Error>) -> Void) {
        followSystemService.followUser(uid: uid) { result in
            completion(result)
        }
    }

    func unfollowSubscriber(uid: String, completion: @escaping (Result<FollowStatus, Error>) -> Void) {
        followSystemService.unfollowUser(uid: uid) { result in
            completion(result)
        }
    }
}

extension ActivityService {

    func getAdditionalDataFor(events: [ActivityEvent], completion: @escaping (Result<[ActivityEvent], Error>) -> Void) {
        let currentUserID = AuthenticationService.shared.getCurrentUserUID()!
        let dispatchGroup = DispatchGroup()

        for event in events {
            dispatchGroup.enter()
            userDataService.getUser(for: event.userID) { result in
                switch result {
                case .success(let user):
                    event.user = user

                    if let profilePhotoURL = user.profilePhotoURL {
                        dispatchGroup.enter()
                        self.getImage(for: profilePhotoURL) { result in
                            switch result {
                            case .success(let profilePhoto):
                                event.user?.setProfilePhoto(profilePhoto)
                            case .failure(let error):
                                completion(.failure(error))
                            }
                            dispatchGroup.leave()
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
                dispatchGroup.leave()
            }

            if event.eventType == .postLiked || event.eventType == .postCommented {
                dispatchGroup.enter()
                userPostsService.getPost(ofUser: currentUserID, postID: event.postID!) { result in
                    switch result {
                    case .success(let post):
                        self.getImage(for: post.photoURL) { result in
                            switch result {
                            case .success(let postImage):
                                post.image = postImage
                                event.post = post
                            case .failure(let error):
                                completion(.failure(error))
                            }
                            dispatchGroup.leave()
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
        dispatchGroup.notify(queue: .main) {
            completion(.success(events))
        }
    }
}

