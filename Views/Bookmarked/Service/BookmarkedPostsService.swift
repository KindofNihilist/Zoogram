//
//  BookmarkedPostsService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 30.12.2023.
//

import Foundation

protocol BookmarkedPostsServiceProtocol: PostsNetworking<Bookmark> {
    var bookmarksService: BookmarksSystemServiceProtocol { get }
    var likeSystemService: LikeSystemServiceProtocol { get }
    var userPostsService: UserPostsServiceProtocol { get }
}

class BookmarkedPostsService: ImageService, BookmarkedPostsServiceProtocol {
    var numberOfAllItems: UInt = 0
    var numberOfRetrievedItems: UInt = 0
    var numberOfItemsToGet: UInt = 18

    var lastReceivedItemKey: String = ""
    var isAlreadyPaginating: Bool = false
    var hasHitTheEndOfPosts: Bool = false

    let bookmarksService: BookmarksSystemServiceProtocol
    let likeSystemService: LikeSystemServiceProtocol
    let userPostsService: UserPostsServiceProtocol

    init(bookmarksService: BookmarksSystemServiceProtocol,
         likeSystemService: LikeSystemServiceProtocol,
         userPostsService: UserPostsServiceProtocol)
    {
        self.bookmarksService = bookmarksService
        self.likeSystemService = likeSystemService
        self.userPostsService = userPostsService
    }

    func getNumberOfItems(completion: @escaping (Result<Int, Error>) -> Void = {_ in}) {
        bookmarksService.getBookmarksCount { result in
            switch result {
            case .success(let bookmarksCount):
                self.numberOfAllItems = UInt(bookmarksCount)
                completion(.success(bookmarksCount))
            case .failure(let error):
                completion(.failure(error))
            }

        }
    }

    func getItems(completion: @escaping ([Bookmark]?, Error?) -> Void) {
        self.getNumberOfItems() { result in

            switch result {
            case .success(let numberOfItems):
                self.bookmarksService.getBookmarks(numberOfBookmarksToGet: self.numberOfItemsToGet) { result in
                    switch result {
                    case .success((let bookmarks, let lastRetrievedBookmarkKey)):
                        guard bookmarks.isEmpty != true else {
                            self.hasHitTheEndOfPosts = true
                            completion(nil, nil)
                            return
                        }
                        self.getAdditionalDataFor(bookmarks: bookmarks) { result in
                            switch result {
                            case .success(let bookmarksWithAdditionalData):
                                self.hasHitTheEndOfPosts = false
                                self.lastReceivedItemKey = lastRetrievedBookmarkKey
                                self.numberOfRetrievedItems = UInt(bookmarks.count)
                                if numberOfItems == self.numberOfRetrievedItems {
                                    self.hasHitTheEndOfPosts = true
                                }
                                completion(bookmarksWithAdditionalData, nil)
                            case .failure(let error):
                                completion(nil, error)
                            }
                        }
                    case .failure(let error):
                        completion(nil, error)
                    }
                }
            case .failure(let error):
                completion(nil, error)

            }
        }
    }

    func getMoreItems(completion: @escaping ([Bookmark]?, Error?) -> Void) {
        guard isAlreadyPaginating == false, lastReceivedItemKey != "" else {
            return
        }

        isAlreadyPaginating = true

        bookmarksService.getMoreBookmarks(after: lastReceivedItemKey, numberOfBookmarksToGet: numberOfItemsToGet) { result in
            switch result {
            case .success((let bookmarks, let lastRetrievedBookmarkKey)):
                guard bookmarks.isEmpty != true, lastRetrievedBookmarkKey != self.lastReceivedItemKey else {
                    self.isAlreadyPaginating = false
                    self.hasHitTheEndOfPosts = true
                    completion(nil, nil)
                    return
                }
                self.getAdditionalDataFor(bookmarks: bookmarks) { result in
                    switch result {
                    case .success(let bookmarksWithAdditionalData):
                        self.numberOfRetrievedItems += UInt(bookmarks.count)
                        self.lastReceivedItemKey = lastRetrievedBookmarkKey
                        if self.numberOfAllItems == self.numberOfRetrievedItems {
                            self.hasHitTheEndOfPosts = true
                        }
                        completion(bookmarksWithAdditionalData, nil)
                    case .failure(let error):
                        self.isAlreadyPaginating = false
                        completion(nil, error)
                    }
                }
            case .failure(let error):
                self.isAlreadyPaginating = false
                completion(nil, error)
            }
        }
    }

    func getAdditionalDataFor(bookmarks: [Bookmark], completion: @escaping (Result<[Bookmark], Error>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var associatedPosts: [UserPost?] = bookmarks.map { _ in return nil }

        for (index, bookmark) in bookmarks.enumerated() {
            dispatchGroup.enter()
            userPostsService.getPost(ofUser: bookmark.postAuthorID, postID: bookmark.postID) { result in
                switch result {
                case .success(let post):
                    associatedPosts[index] = post
                case .failure(let error):
                    completion(.failure(error))
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            let unwrappedPosts = associatedPosts.compactMap { return $0 }
            self.getAdditionalPostDataFor(postsOfMultipleUsers: unwrappedPosts) { result in
                switch result {
                case .success(let postsWithAdditionalData):
                    let bookmarksWithAssociatedPostAdditionalData = bookmarks.enumerated().map { (index, bookmark) in
                        bookmark.associatedPost = PostViewModel(post: postsWithAdditionalData[index])
                        return bookmark
                    }
                    completion(.success(bookmarksWithAssociatedPostAdditionalData))
                case .failure(let error):
                    completion(.failure(error))
                }
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
            bookmarksService.removeBookmark(postID: postID) { bookmarkState in
                completion(bookmarkState)
                print("Successfully removed a bookmark")
            }
        case .notBookmarked:
            bookmarksService.bookmarkPost(postID: postID, authorID: authorID) { bookmarkState in
                completion(bookmarkState)
                print("Successfully bookmarked a post")
            }
        }

    }
}

