//
//  UserSearchService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 08.04.2024.
//

import Foundation

protocol DiscoverServiceProtocol: PostsNetworking<UserPost> {
    func searchUserWith(username: String, completion: @escaping (Result<[ZoogramUser], Error>) -> Void)
}

class DiscoverService: ImageService, DiscoverServiceProtocol {

    var numberOfItemsToGet: UInt = 18
    var numberOfAllItems: UInt = 0
    var numberOfRetrievedItems: UInt = 0
    var lastReceivedItemKey: String = ""
    var isAlreadyPaginating: Bool = false
    var hasHitTheEndOfPosts: Bool = false

    let userDataService: UserDataServiceProtocol
    let discoverPostsService: DiscoverPostsServiceProtocol
    let likeSystemService: LikeSystemServiceProtocol
    let userPostsService: UserPostsServiceProtocol
    let bookmarksService: BookmarksSystemServiceProtocol

    init(userDataService: UserDataServiceProtocol,
         discoverPostsService: DiscoverPostsServiceProtocol,
         likeSystemService: LikeSystemServiceProtocol,
         userPostsService: UserPostsServiceProtocol,
         bookmarksService: BookmarksSystemServiceProtocol) {
        self.userDataService = userDataService
        self.discoverPostsService = discoverPostsService
        self.likeSystemService = likeSystemService
        self.userPostsService = userPostsService
        self.bookmarksService = bookmarksService
    }

    func getNumberOfItems(completion: @escaping (Result<Int, Error>) -> Void) {
        discoverPostsService.getDiscoverPostsCount { result in
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
        getNumberOfItems { _ in
            self.discoverPostsService.getDiscoverPosts(quantity: self.numberOfItemsToGet) { result in
                switch result {
                case .success((let posts, let lastPostKey)):
                    guard posts.isEmpty != true else {
                        self.hasHitTheEndOfPosts = true
                        completion(nil, nil)
                        return
                    }
                    self.getAdditionalPostDataFor(postsOfMultipleUsers: posts) { result in
                        switch result {
                        case .success(let postsWithAdditionalData):
                            self.lastReceivedItemKey = lastPostKey
                            self.hasHitTheEndOfPosts = false
                            self.numberOfRetrievedItems = UInt(postsWithAdditionalData.count)
                            if self.numberOfRetrievedItems == self.numberOfAllItems {
                                self.hasHitTheEndOfPosts = true
                            }
                            completion(postsWithAdditionalData, nil)
                        case .failure(let error):
                            completion(nil, ServiceError.couldntLoadPosts)
                            print(error)
                        }
                    }

                case .failure(let error):
                    completion(nil, error)
                }
            }
        }
    }

    func getMoreItems(completion: @escaping ([UserPost]?, Error?) -> Void) {
        guard isAlreadyPaginating == false, lastReceivedItemKey != "" else {
            return
        }

        isAlreadyPaginating = true

        discoverPostsService.getMoreDiscoverPosts(quantity: numberOfItemsToGet, after: lastReceivedItemKey) { result in
            switch result {
            case .success((let posts, let lastPostKey)):
                guard posts.isEmpty != true, lastPostKey != self.lastReceivedItemKey else {
                    self.isAlreadyPaginating = false
                    self.hasHitTheEndOfPosts = true
                    completion(nil, nil)
                    return
                }
                self.getAdditionalPostDataFor(postsOfMultipleUsers: posts) { result in
                    switch result {
                    case .success(let postsWidthAdditionalData):
                        self.lastReceivedItemKey = lastPostKey
                        self.numberOfRetrievedItems += UInt(posts.count)
                        if self.numberOfRetrievedItems == self.numberOfAllItems {
                            self.hasHitTheEndOfPosts = true
                        }
                        completion(postsWidthAdditionalData, nil)
                    case .failure(let error):
                        self.isAlreadyPaginating = false
                        completion(nil, ServiceError.couldntLoadPosts)
                    }
                }
            case .failure(let error):
                self.isAlreadyPaginating = false
                completion(nil, error)
            }
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
                    let currentUserID = AuthenticationService.shared.getCurrentUserUID()!
                    let eventID = ActivitySystemService.shared.createEventUID()
                    let activityEvent = ActivityEvent(eventType: .postLiked, userID: currentUserID, postID: postID, eventID: eventID, date: Date())
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

    func searchUserWith(username: String, completion: @escaping (Result<[ZoogramUser], Error>) -> Void) {
        userDataService.searchUserWith(username: username) { result in
            switch result {
            case .success(let users):
                let dispatchGroup = DispatchGroup()

                for user in users {
                    if let profilePictureURL = user.profilePhotoURL {
                        dispatchGroup.enter()

                        self.getImage(for: profilePictureURL) { result in
                            switch result {
                            case .success(let profilePhoto):
                                user.setProfilePhoto(profilePhoto)
                            case .failure(let error):
                                completion(.failure(error))
                            }
                            dispatchGroup.leave()
                        }
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    completion(.success(users))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
