//
//  HomeFeedService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 09.05.2023.
//

import Foundation

protocol HomeFeedServiceProtocol: PostsNetworking<UserPost> {
    func makeANewPost(post: UserPost, progressUpdateCallback: @escaping (Progress?) -> Void) async throws
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

    func getNumberOfItems() async throws -> Int {
        let numberOfFeedPosts = try await feedService.getFeedPostsCount()
        self.numberOfAllItems = UInt(numberOfFeedPosts)
        return numberOfFeedPosts
    }

    func getItems() async throws -> [UserPost]? {
        _ = try await getNumberOfItems()
        let feedPosts = try await feedService.getPostsForTimeline(quantity: numberOfItemsToGet)
        guard feedPosts.items.isEmpty != true else {
            self.hasHitTheEndOfPosts = true
            return nil
        }
        let postsWithAdditionalData = try await getAdditionalPostDataFor(postsOfMultipleUsers: feedPosts.items)
        self.lastReceivedItemKey = feedPosts.lastRetrievedItemKey
        self.hasHitTheEndOfPosts = false
        self.numberOfRetrievedItems = UInt(postsWithAdditionalData.count)
        if self.numberOfRetrievedItems == self.numberOfAllItems {
            self.hasHitTheEndOfPosts = true
        }
        return postsWithAdditionalData
    }

    func getMoreItems() async throws -> [UserPost]? {
        guard isAlreadyPaginating == false, lastReceivedItemKey != "" else {
            return nil
        }

        isAlreadyPaginating = true

        do {
            let feedPosts = try await feedService.getMorePostsForTimeline(quantity: numberOfItemsToGet, after: lastReceivedItemKey)
            guard feedPosts.items.isEmpty != true, feedPosts.lastRetrievedItemKey != self.lastReceivedItemKey else {
                self.isAlreadyPaginating = false
                self.hasHitTheEndOfPosts = true
                return nil
            }
            let postsWithAdditionalData = try await getAdditionalPostDataFor(postsOfMultipleUsers: feedPosts.items)
            self.lastReceivedItemKey = feedPosts.lastRetrievedItemKey
            self.numberOfRetrievedItems += UInt(feedPosts.items.count)
            if self.numberOfRetrievedItems == self.numberOfAllItems {
                self.hasHitTheEndOfPosts = true
            }
            return postsWithAdditionalData
        } catch {
            self.isAlreadyPaginating = false
            throw error
        }
    }

    func makeANewPost(post: UserPost, progressUpdateCallback: @escaping (Progress?) -> Void) async throws {
        guard let image = post.image else {
            return
        }
        let fileName = "\(post.postID)_post.png"

        let uploadedPhotoURL = try await storageManager.uploadPostPhoto(photo: image, fileName: fileName) { progress in
            progressUpdateCallback(progress)
        }
        post.photoURL = uploadedPhotoURL.absoluteString
        try await userPostsService.insertNewPost(post: post)
    }

    func likePost(postID: String, likeState: LikeState, postAuthorID: String) async throws -> LikeState {
        switch likeState {
        case .liked:
            try await likeSystemService.removeLikeFromPost(postID: postID)
            try await ActivitySystemService.shared.removeLikeEventForPost(postID: postID, postAuthorID: postAuthorID)
            return .notLiked
        case .notLiked:
            try await likeSystemService.likePost(postID: postID)
            let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
            let eventID = ActivitySystemService.shared.createEventUID()
            let activityEvent = ActivityEvent(eventType: .postLiked, userID: currentUserID, postID: postID, eventID: eventID, date: Date())
            try await ActivitySystemService.shared.addEventToUserActivity(event: activityEvent, userID: postAuthorID)
            return .liked
        }
    }

    func deletePost(postModel: PostViewModel) async throws {
        try await userPostsService.deletePost(postID: postModel.postID, postImageURL: postModel.postImageURL)
    }

    func bookmarkPost(postID: String, authorID: String, bookmarkState: BookmarkState) async throws -> BookmarkState {
        switch bookmarkState {
        case .bookmarked:
            let bookmarkState = try await bookmarksService.removeBookmark(postID: postID)
            return bookmarkState
        case .notBookmarked:
            let bookmarkState = try await bookmarksService.bookmarkPost(postID: postID, authorID: authorID)
            return bookmarkState
        }
    }
}

