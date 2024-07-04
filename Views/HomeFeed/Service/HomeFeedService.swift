//
//  HomeFeedService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 09.05.2023.
//

import Foundation

protocol HomeFeedServiceProtocol: PostsNetworking<UserPost> {
    func makeANewPost(post: UserPost, progressUpdateCallback: @Sendable @escaping (Progress?) -> Void) async throws
}

final class HomeFeedService: HomeFeedServiceProtocol {

    internal let paginationManager = PaginationManager(numberOfItemsToGetPerPagination: 10)

    private let feedService: FeedService
    private let likeSystemService: LikeSystemServiceProtocol
    private let userPostsService: UserPostsServiceProtocol
    private let bookmarksService: BookmarksSystemServiceProtocol
    private let storageManager: StorageManagerProtocol

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
        await self.paginationManager.setNumberOfAllItems(numberOfFeedPosts)
        return numberOfFeedPosts
    }

    func getItems() async throws -> [UserPost]? {
        do {
            print("inside getItems")
            let isPaginating = await paginationManager.isPaginating()
            guard isPaginating == false else { return nil }
            print("past isPaginating")
            await paginationManager.startPaginating()
            let numberOfItemsToGet = paginationManager.numberOfItemsToGetPerPagination
            async let numberOfAllItems = getNumberOfItems()
            async let feedPosts = feedService.getPostsForTimeline(quantity: numberOfItemsToGet)

            guard try await feedPosts.items.isEmpty != true else {
                await self.paginationManager.setHasHitEndOfItemsStatus(to: true)
                await paginationManager.finishPaginating()
                return nil
            }

            let postsWithAdditionalData = try await getAdditionalPostDataFor(postsOfMultipleUsers: feedPosts.items)
            let lastRetrievedItemKey = try await feedPosts.lastRetrievedItemKey
            print("received \(postsWithAdditionalData.count) posts")
            await paginationManager.resetNumberOfRetrievedItems()
            await paginationManager.setLastReceivedItemKey(lastRetrievedItemKey)
            await paginationManager.setHasHitEndOfItemsStatus(to: false)
            await paginationManager.updateNumberOfRetrievedItems(value: postsWithAdditionalData.count)

            let numberOfRetrievedItems = await paginationManager.getNumberOfRetrievedItems()
            if try await numberOfRetrievedItems == numberOfAllItems {
                print("hasHitEndOfItems")
                await paginationManager.setHasHitEndOfItemsStatus(to: true)
            }
            await paginationManager.finishPaginating()
            return postsWithAdditionalData
        } catch {
            await paginationManager.finishPaginating()
            throw error
        }
    }

    func getMoreItems() async throws -> [UserPost]? {
        do {
            let lastReceivedItemKey = await paginationManager.getLastReceivedItemKey()
            let isPaginating = await paginationManager.isPaginating()
            guard isPaginating == false, lastReceivedItemKey != "" else { return nil }
            await paginationManager.startPaginating()

            let numberOfItemsToGet = paginationManager.numberOfItemsToGetPerPagination
            let feedPosts = try await feedService.getMorePostsForTimeline(quantity: numberOfItemsToGet, after: lastReceivedItemKey)

            guard feedPosts.items.isEmpty != true, feedPosts.lastRetrievedItemKey != lastReceivedItemKey else {
                await self.paginationManager.finishPaginating()
                await paginationManager.setHasHitEndOfItemsStatus(to: true)
                return nil
            }

            let postsWithAdditionalData = try await getAdditionalPostDataFor(postsOfMultipleUsers: feedPosts.items)
            await paginationManager.setLastReceivedItemKey(feedPosts.lastRetrievedItemKey)
            await paginationManager.updateNumberOfRetrievedItems(value: postsWithAdditionalData.count)
            let numberOfAllItems = await paginationManager.getNumberOfAllItems()
            let numberOfRetrievedItems = await paginationManager.getNumberOfRetrievedItems()

            if numberOfRetrievedItems == numberOfAllItems {
                await paginationManager.setHasHitEndOfItemsStatus(to: true)
            }
            await paginationManager.finishPaginating()
            return postsWithAdditionalData
        } catch {
            await paginationManager.finishPaginating()
            throw error
        }
    }

    func makeANewPost(post: UserPost, progressUpdateCallback: @Sendable @escaping (Progress?) -> Void) async throws {
        guard let image = post.image else {
            return
        }
        var postToPost = post
        let fileName = "\(postToPost.postID)_post.png"

        let uploadedPhotoURL = try await storageManager.uploadPostPhoto(photo: image, fileName: fileName) { progress in
            progressUpdateCallback(progress)
        }
        postToPost.photoURL = uploadedPhotoURL.absoluteString
        try await userPostsService.insertNewPost(post: postToPost)
    }

    func likePost(postID: String, likeState: LikeState, postAuthorID: String) async throws {
        switch likeState {
        case .liked:
            async let likeRemovalTask: Void = likeSystemService.removeLikeFromPost(postID: postID)
            async let activityRemovalTask: Void = ActivitySystemService.shared.removeLikeEventForPost(postID: postID, postAuthorID: postAuthorID)
            _ = try await [likeRemovalTask, activityRemovalTask]
        case .notLiked:
            let activityEvent = ActivityEvent.createActivityEventFor(likedPostID: postID)
            async let likeTask: Void = likeSystemService.likePost(postID: postID)
            async let activityEventTask: Void = ActivitySystemService.shared.addEventToUserActivity(event: activityEvent, userID: postAuthorID)
            _ = try await [likeTask, activityEventTask]
        }
    }

    func deletePost(postModel: PostViewModel) async throws {
        try await userPostsService.deletePost(postID: postModel.postID, postImageURL: postModel.postImageURL)
    }

    func bookmarkPost(postID: String, authorID: String, bookmarkState: BookmarkState) async throws {
        switch bookmarkState {
        case .bookmarked:
            try await bookmarksService.removeBookmark(postID: postID)
        case .notBookmarked:
            try await bookmarksService.bookmarkPost(postID: postID, authorID: authorID)
        }
    }
}
