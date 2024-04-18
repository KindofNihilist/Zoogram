//
//  UserProfileService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.04.2023.
//

import Foundation

protocol UserProfileServiceProtocol: PostsNetworking<UserPost> {
    var userID: String { get }
    var dispatchGroup: DispatchGroup { get set }

    var followService: FollowSystemProtocol { get }
    var userPostsService: UserPostsServiceProtocol { get }
    var userDataService: UserDataServiceProtocol { get }
    var likeSystemService: LikeSystemServiceProtocol { get }
    var bookmarksService: BookmarksSystemServiceProtocol { get }

    func getFollowersCount(completion: @escaping (Result<Int, Error>) -> Void)
    func getFollowingCount(completion: @escaping (Result<Int, Error>) -> Void)
    func getUserData(completion: @escaping (Result<ZoogramUser, Error>) -> Void)
    func followUser(completion: @escaping (Result<FollowStatus, Error>) -> Void)
    func unfollowUser(completion: @escaping (Result<FollowStatus, Error>) -> Void)
}

typealias HasHitTheEnd = Bool

class UserProfileService: ImageService, UserProfileServiceProtocol {
    
    var numberOfRetrievedItems: UInt = 0
    var numberOfAllItems: UInt = 0
    var numberOfItemsToGet: UInt = 12
    var lastReceivedItemKey: String = ""
    var isAlreadyPaginating: Bool = false
    var hasHitTheEndOfPosts: HasHitTheEnd = false

    var userID: String

    let followService: FollowSystemProtocol
    let userPostsService: UserPostsServiceProtocol
    let userDataService: UserDataServiceProtocol
    let likeSystemService: LikeSystemServiceProtocol
    let bookmarksService: BookmarksSystemServiceProtocol

    var dispatchGroup = DispatchGroup()

    init(userID: String, 
         followService: FollowSystemProtocol,
         userPostsService: UserPostsServiceProtocol,
         userService: UserDataServiceProtocol,
         likeSystemService: LikeSystemServiceProtocol,
         bookmarksService: BookmarksSystemServiceProtocol) {
        self.userID = userID
        self.followService = followService
        self.userPostsService = userPostsService
        self.userDataService = userService
        self.likeSystemService = likeSystemService
        self.bookmarksService = bookmarksService
        self.dispatchGroup = DispatchGroup()
    }

    func getFollowersCount(completion: @escaping (Result<Int, Error>) -> Void) {
        followService.getFollowersNumber(for: userID) { result in
            completion(result)
        }
    }

    func getFollowingCount(completion: @escaping (Result<Int, Error>) -> Void) {
        followService.getFollowingNumber(for: userID) { result in
            completion(result)
        }
    }

    func getUserData(completion: @escaping (Result<ZoogramUser, Error>) -> Void) {
        let currentUserID = AuthenticationService.shared.getCurrentUserUID()

        if userID == currentUserID {
            userDataService.getCurrentUser { result in
                completion(result)
            }
        } else {
            userDataService.getUser(for: userID) { result in
                switch result {
                case .success(let user):
                    if let profilePhotoURL = user.profilePhotoURL {
                        self.getImage(for: profilePhotoURL) { result in
                            switch result {
                            case .success(let profilePhoto):
                                user.setProfilePhoto(profilePhoto)
                                completion(.success(user))
                            case .failure(let error):
                                completion(.failure(error))
                                return
                            }
                        }
                    } else {
                        completion(.success(user))
                    }

                case .failure(let error):
                    completion(.failure(error))
                    return
                }
            }
        }
    }

    func getNumberOfItems(completion: @escaping (Result<Int, Error>) -> Void) {
        userPostsService.getPostCount(for: userID) { result in
            switch result {
            case .success(let postsCount):
                self.numberOfAllItems = UInt(postsCount)
                completion(.success(postsCount))
            case .failure(let error):
                completion(.failure(error))
            }

        }
    }

    func getItems(completion: @escaping ([UserPost]?, Error?) -> Void) {

        userPostsService.getPosts(quantity: numberOfItemsToGet, for: userID) { [weak self] result in
            switch result {
            case .success((let posts, let lastRetrievedPostKey)):
                guard posts.isEmpty != true else {
                    self?.hasHitTheEndOfPosts = true
                    completion(nil, nil)
                    return
                }
                self?.getAdditionalPostDataFor(postsOfSingleUser: posts) { result in
                    switch result {
                    case .success(let postsWithAdditionalData):
                        self?.lastReceivedItemKey = lastRetrievedPostKey
                        self?.hasHitTheEndOfPosts = false
                        self?.numberOfRetrievedItems = UInt(posts.count)
                        if self?.numberOfRetrievedItems == self?.numberOfAllItems {
                            self?.hasHitTheEndOfPosts = true
                        }
                        completion(postsWithAdditionalData, nil)
                    case .failure(_):
                        completion(nil, ServiceError.couldntLoadPosts)
                        return
                    }
                }
            case .failure(let error):
                completion(nil, error)
                return
            }
        }
    }

    func getMoreItems(completion: @escaping ([UserPost]?, Error?) -> Void) {
        guard isAlreadyPaginating == false, lastReceivedItemKey != "" else {
            return
        }
        isAlreadyPaginating = true
        userPostsService.getMorePosts(quantity: numberOfItemsToGet, after: lastReceivedItemKey, for: userID) { [weak self] result in
            switch result {
            case .success((let posts, let lastRetrievedPostKey)):
                guard posts.isEmpty != true, lastRetrievedPostKey != self?.lastReceivedItemKey else {
                    self?.hasHitTheEndOfPosts = true
                    self?.isAlreadyPaginating = false
                    completion(nil, nil)
                    return
                }
                self?.getAdditionalPostDataFor(postsOfSingleUser: posts) { result in
                    switch result {
                    case .success(let postsWithAdditionalData):
                        self?.numberOfRetrievedItems += UInt(posts.count)
                        self?.lastReceivedItemKey = lastRetrievedPostKey
                        if self?.numberOfRetrievedItems == self?.numberOfAllItems {
                            self?.hasHitTheEndOfPosts = true
                        }
                        completion(postsWithAdditionalData, nil)
                    case .failure(_):
                        completion(nil, ServiceError.couldntLoadPosts)
                        self?.isAlreadyPaginating = false
                        return
                    }
                }
            case .failure(let error):
                completion(nil, error)
                self?.isAlreadyPaginating = false
                return
            }
        }
    }

    func followUser(completion: @escaping (Result<FollowStatus, Error>) -> Void) {
        followService.followUser(uid: userID) { result in
            completion(result)
        }
    }

    func unfollowUser(completion: @escaping (Result<FollowStatus, Error>) -> Void) {
        followService.unfollowUser(uid: userID) { result in
            completion(result)
        }
    }

    func likePost(postID: String, likeState: LikeState, postAuthorID: String, completion: @escaping (Result<LikeState, Error>) -> Void) {
        switch likeState {
        case .liked:
            likeSystemService.removeLikeFromPost(postID: postID) { result in
                switch result {
                case .success:
                    ActivitySystemService.shared.removeLikeEventForPost(postID: postID, postAuthorID: postAuthorID)
                    completion(.success(.notLiked))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .notLiked:
            likeSystemService.likePost(postID: postID) { result in
                switch result {
                case .success:
                    let activityEvent = ActivityEvent.createActivityEventFor(likedPostID: postID)
                    ActivitySystemService.shared.addEventToUserActivity(event: activityEvent, userID: postAuthorID)
                    completion(.success(.liked))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    func deletePost(postModel: PostViewModel, completion: @escaping (VoidResult) -> Void) {
        userPostsService.deletePost(postID: postModel.postID, postImageURL: postModel.postImageURL) { result in
            completion(result)
        }
    }

    func bookmarkPost(postID: String, authorID: String, bookmarkState: BookmarkState, completion: @escaping (Result<BookmarkState, Error>) -> Void) {
        switch bookmarkState {
        case .bookmarked:
            bookmarksService.removeBookmark(postID: postID) { result in
                completion(result)
            }
        case .notBookmarked:
            bookmarksService.bookmarkPost(postID: postID, authorID: authorID) { result in
                completion(result)
            }
        }

    }
}

func createUserProfileDefaultServiceFor(userID: String) -> UserProfileService {
    UserProfileService(userID: userID,
                       followService: FollowSystemService.shared,
                       userPostsService: UserPostsService.shared,
                       userService: UserDataService.shared,
                       likeSystemService: LikeSystemService.shared,
                       bookmarksService: BookmarksSystemService.shared)
}

