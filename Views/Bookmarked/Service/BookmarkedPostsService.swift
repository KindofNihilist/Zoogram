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

final class BookmarkedPostsService: BookmarkedPostsServiceProtocol {

    internal let paginationManager = PaginationManager(numberOfItemsToGetPerPagination: 18)

    internal let bookmarksService: BookmarksSystemServiceProtocol
    internal let likeSystemService: LikeSystemServiceProtocol
    internal let userPostsService: UserPostsServiceProtocol
    internal let userDataService: UserDataServiceProtocol
    internal let imageService: ImageServiceProtocol
    internal let commentsService: CommentSystemServiceProtocol

    init(bookmarksService: BookmarksSystemServiceProtocol,
         likeSystemService: LikeSystemServiceProtocol,
         userPostsService: UserPostsServiceProtocol,
         userDataService: UserDataServiceProtocol,
         imageService: ImageServiceProtocol,
         commentsService: CommentSystemServiceProtocol) {
        self.bookmarksService = bookmarksService
        self.likeSystemService = likeSystemService
        self.userPostsService = userPostsService
        self.userDataService = userDataService
        self.imageService = imageService
        self.commentsService = commentsService
    }

    func getNumberOfItems() async throws -> Int {
        let bookmarksCount = try await bookmarksService.getBookmarksCount()
        await paginationManager.setNumberOfAllItems(bookmarksCount)
        return bookmarksCount
    }

    func getItems() async throws -> [Bookmark]? {
        do {
            guard await paginationManager.isPaginating() == false else { return nil }
            await paginationManager.startPaginating()

            let numberOfItemsToGet = paginationManager.numberOfItemsToGetPerPagination
            async let numberOfAllItems = getNumberOfItems()
            async let retrievedBookmarks = bookmarksService.getBookmarks(numberOfBookmarksToGet: numberOfItemsToGet)

            guard try await retrievedBookmarks.items.isEmpty != true else {
                await paginationManager.finishPaginating()
                return nil
            }

            let bookmarksWithAdditionalData = try await getAdditionalDataFor(bookmarks: retrievedBookmarks.items)
            let lastRetrievedItemKey = try await retrievedBookmarks.lastRetrievedItemKey
            await paginationManager.setLastReceivedItemKey(lastRetrievedItemKey)
            await paginationManager.resetNumberOfRetrievedItems()
            await paginationManager.updateNumberOfRetrievedItems(value: bookmarksWithAdditionalData.count)
            await paginationManager.finishPaginating()
            return bookmarksWithAdditionalData
        } catch {
            await paginationManager.finishPaginating()
            throw error
        }
    }

    func getMoreItems() async throws -> [Bookmark]? {
        do {
            let lastReceivedItemKey = await paginationManager.getLastReceivedItemKey()
            let isPaginating = await paginationManager.isPaginating()
            guard isPaginating == false, lastReceivedItemKey != "" else { return nil }
            await paginationManager.startPaginating()

            let numberOfItemsToGet = paginationManager.numberOfItemsToGetPerPagination
            let retrievedBookmarks = try await bookmarksService.getMoreBookmarks(after: lastReceivedItemKey, numberOfBookmarksToGet: numberOfItemsToGet)

            guard retrievedBookmarks.items.isEmpty != true, retrievedBookmarks.lastRetrievedItemKey != lastReceivedItemKey else {
                await paginationManager.finishPaginating()
                return nil
            }

            let bookmarksWithAdditionalData = try await getAdditionalDataFor(bookmarks: retrievedBookmarks.items)
            await paginationManager.updateNumberOfRetrievedItems(value: bookmarksWithAdditionalData.count)
            await paginationManager.setLastReceivedItemKey(retrievedBookmarks.lastRetrievedItemKey)
            await paginationManager.finishPaginating()
            return bookmarksWithAdditionalData
        } catch {
            await paginationManager.finishPaginating()
            throw error
        }
    }

    func getAdditionalDataFor(bookmarks: [Bookmark]) async throws -> [Bookmark] {
        let bookmarksWithAssociatedPosts = try await withThrowingTaskGroup(of: (Int, UserPost).self, returning: [Bookmark].self) { group in
            for (index, bookmark) in bookmarks.enumerated() {
                group.addTask {
                    let bookmarkedPost = try await self.userPostsService.getPost(ofUser: bookmark.postAuthorID, postID: bookmark.postID)
                    let postWithAdditionalData = try await self.getAdditionalPostDataFor(bookmarkedPost)
                    return (index, postWithAdditionalData)
                }
            }

            var bookmarks = bookmarks
            for try await (index, post) in group {
                bookmarks[index].associatedPost = PostViewModel(post: post)
            }
            return bookmarks
        }
        return bookmarksWithAssociatedPosts
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
