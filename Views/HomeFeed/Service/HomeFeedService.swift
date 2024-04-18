//
//  HomeFeedService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 09.05.2023.
//

import Foundation

protocol HomeFeedServiceProtocol: PostsNetworking<UserPost> {
    func makeANewPost(post: UserPost, progressUpdateCallback: @escaping (Progress?) -> Void, completion: @escaping (VoidResult) -> Void)
}

class HomeFeedService: ImageService, HomeFeedServiceProtocol {

    var numberOfAllItems: UInt = 0
    var numberOfRetrievedItems: UInt = 0
    var numberOfItemsToGet: UInt = 8

    let feedService: FeedService
    let likeSystemService: LikeSystemServiceProtocol
    let userPostsService: UserPostsServiceProtocol
    let bookmarksService: BookmarksSystemServiceProtocol
    let storageManager: StorageManagerProtocol

    var lastReceivedItemKey: String = ""
    var isAlreadyPaginating: Bool = false
    var isPaginationAllowed: Bool = true
    var hasHitTheEndOfPosts: Bool = false

    init(feedService: FeedService, 
         likeSystemService: LikeSystemService,
         userPostsService: UserPostsService,
         bookmarksService: BookmarksSystemService,
         storageManager: StorageManager) {
        self.feedService = feedService
        self.likeSystemService = likeSystemService
        self.userPostsService = userPostsService
        self.bookmarksService = bookmarksService
        self.storageManager = storageManager
    }

    func getNumberOfItems(completion: @escaping (Result<Int, Error>) -> Void) {
        feedService.getFeedPostsCount { result in
            switch result {
            case .success(let postCount):
                self.numberOfAllItems = UInt(postCount)
                completion(.success(postCount))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getItems(completion: @escaping ([UserPost]?, Error?) -> Void) {
        getNumberOfItems { _ in
            self.feedService.getPostsForTimeline(quantity: self.numberOfItemsToGet) { [weak self] result in
                switch result {
                case .success((let posts, let lastPostKey)):
                    guard posts.isEmpty != true else {
                        self?.hasHitTheEndOfPosts = true
                        completion(nil, nil)
                        return
                    }
                    self?.getAdditionalPostDataFor(postsOfMultipleUsers: posts) { result in
                        switch result {
                        case .success(let postsWithAdditionalData):
                            self?.lastReceivedItemKey = lastPostKey
                            self?.hasHitTheEndOfPosts = false
                            self?.numberOfRetrievedItems = UInt(postsWithAdditionalData.count)
                            if self?.numberOfRetrievedItems == self?.numberOfAllItems {
                                self?.hasHitTheEndOfPosts = true
                            }
                            completion(postsWithAdditionalData, nil)
                        case .failure(let error):
                            completion(nil, ServiceError.couldntLoadPosts)
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

        feedService.getMorePostsForTimeline(quantity: numberOfItemsToGet, after: lastReceivedItemKey) { [weak self] result in
            switch result {
            case .success((let posts, let lastRetrievedPostKey)):
                guard posts.isEmpty != true, lastRetrievedPostKey != self?.lastReceivedItemKey else {
                    self?.isAlreadyPaginating = false
                    self?.hasHitTheEndOfPosts = true
                    completion(nil, nil)
                    return
                }
                self?.getAdditionalPostDataFor(postsOfMultipleUsers: posts) { result in
                    switch result {
                    case .success(let postsWithAdditionalData):
                        self?.lastReceivedItemKey = lastRetrievedPostKey
                        self?.numberOfRetrievedItems += UInt(posts.count)
                        if self?.numberOfRetrievedItems == self?.numberOfAllItems {
                            self?.hasHitTheEndOfPosts = true
                        }
                        completion(postsWithAdditionalData, nil)
                    case .failure(let error):
                        self?.isAlreadyPaginating = false
                        completion(nil, ServiceError.couldntLoadPosts)
                    }
                }
            case .failure(let error):
                self?.isAlreadyPaginating = false
                completion(nil, error)
            }
        }
    }

    func makeANewPost(post: UserPost, progressUpdateCallback: @escaping (Progress?) -> Void, completion: @escaping (VoidResult) -> Void) {
        guard let image = post.image else {
            completion(.success)
            return
        }
        let fileName = "\(post.postID)_post.png"

        storageManager.uploadPostPhoto(photo: image, fileName: fileName) { progress in
            progressUpdateCallback(progress)
        } completion: { result in
            switch result {
            case .success(let photoURL):
                post.photoURL = photoURL.absoluteString
                self.userPostsService.insertNewPost(post: post) { result in
                    completion(result)
                }
            case .failure(let error):
                completion(.failure(error))
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
}

