//
//  ActivityServiceAdapter.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 19.05.2023.
//

import Foundation

class ActivityServiceAdapter: ActivityService {

    let activitySystemService: ActivitySystemService
    let followSystemService: FollowSystemService
    let userService: UserService
    let userPostsService: UserPostsService

    init(activitySystemService: ActivitySystemService, followSystemService: FollowSystemService, userService: UserService, userPostsService: UserPostsService) {
        self.activitySystemService = activitySystemService
        self.followSystemService = followSystemService
        self.userService = userService
        self.userPostsService = userPostsService
    }
    
    func observeActivityEvents(completion: @escaping ([ActivityEvent]) -> Void) {
        activitySystemService.observeActivityEvents { events in
            self.getAdditionalDataFor(events: events) { eventsWithAdditionalData in
                completion(eventsWithAdditionalData)
            }
        }
    }

    func updateActivityEventsSeenStatus(events: Set<ActivityEvent>, completion: @escaping () -> Void) {
        activitySystemService.updateActivityEventsSeenStatus(events: events) {
            completion()
        }
    }

    func followSubscriberBack(uid: String, completion: @escaping (FollowStatus) -> Void) {
        followSystemService.followUser(uid: uid) { followStatus in
            completion(followStatus)
        }
    }

    func unfollowSubscriber(uid: String, completion: @escaping (FollowStatus) -> Void) {
        followSystemService.unfollowUser(uid: uid) { followStatus in
            completion(followStatus)
        }
    }
}

extension ActivityServiceAdapter {

    func getAdditionalDataFor(events: [ActivityEvent], completion: @escaping ([ActivityEvent]) -> Void) {
        let currentUserID = AuthenticationManager.shared.getCurrentUserUID()
        let dispatchGroup = DispatchGroup()

        for event in events {
            dispatchGroup.enter()
            userService.getUser(for: event.userID) { user in
                event.user = user
                dispatchGroup.leave()
            }

            if event.eventType == .postLiked || event.eventType == .postCommented {

                dispatchGroup.enter()
                userPostsService.getPost(ofUser: currentUserID, postID: event.postID!) { post in

                     self.getImage(for: post.photoURL) { postImage in
                        post.image = postImage
                        event.post = post
                        dispatchGroup.leave()
                    }
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(events)
        }
    }
}
