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

    func getNumberOfItems() async throws -> Int {
        let bookmarksCount = try await bookmarksService.getBookmarksCount()
        self.numberOfAllItems = UInt(bookmarksCount)
        return bookmarksCount
    }

    func getItems() async throws -> [Bookmark]? {
        let numberOfAllItems = try await getNumberOfItems()
        let paginatedBookmarks = try await bookmarksService.getBookmarks(numberOfBookmarksToGet: numberOfItemsToGet)
        guard paginatedBookmarks.items.isEmpty != true else {
            self.hasHitTheEndOfPosts = true
            return nil
        }
        let bookmarksWithAdditionalData = try await getAdditionalDataFor(bookmarks: paginatedBookmarks.items)
        self.hasHitTheEndOfPosts = false
        self.lastReceivedItemKey = paginatedBookmarks.lastRetrievedItemKey
        self.numberOfRetrievedItems = UInt(paginatedBookmarks.items.count)
        if numberOfAllItems == self.numberOfRetrievedItems {
            self.hasHitTheEndOfPosts = true
        }
        return bookmarksWithAdditionalData
    }

    func getMoreItems() async throws -> [Bookmark]? {
        guard isAlreadyPaginating == false, lastReceivedItemKey != "" else {
            return nil
        }

        isAlreadyPaginating = true
        do {
            let paginatedBookmarks = try await bookmarksService.getMoreBookmarks(after: lastReceivedItemKey, numberOfBookmarksToGet: numberOfItemsToGet)
            guard paginatedBookmarks.items.isEmpty != true, paginatedBookmarks.lastRetrievedItemKey != self.lastReceivedItemKey else {
                self.isAlreadyPaginating = false
                self.hasHitTheEndOfPosts = true
                return nil
            }
            let bookmarksWithAdditionalData = try await getAdditionalDataFor(bookmarks: paginatedBookmarks.items)
            self.numberOfRetrievedItems += UInt(paginatedBookmarks.items.count)
            self.lastReceivedItemKey = paginatedBookmarks.lastRetrievedItemKey
            if self.numberOfAllItems == self.numberOfRetrievedItems {
                self.hasHitTheEndOfPosts = true
            }
            return bookmarksWithAdditionalData
        } catch {
            isAlreadyPaginating = false
            throw error
        }
    }

    func getAdditionalDataFor(bookmarks: [Bookmark]) async throws -> [Bookmark] {
        var associatedPosts = [UserPost]()

        for (index, bookmark) in bookmarks.enumerated() {
            let bookmarkedPost = try await userPostsService.getPost(ofUser: bookmark.postAuthorID, postID: bookmark.postID)
            associatedPosts.insert(bookmarkedPost, at: index)
        }

        let postsWithAdditionalData = try await getAdditionalPostDataFor(postsOfMultipleUsers: associatedPosts)

        let bookmarksWithAssociatedPosts = bookmarks.enumerated().map { (index, bookmark) in
            let associatedPost = postsWithAdditionalData[index]
            bookmark.associatedPost = PostViewModel(post: associatedPost)
            return bookmark
        }
        return bookmarksWithAssociatedPosts
    }

    func likePost(postID: String, likeState: LikeState, postAuthorID: String) async throws -> LikeState {
        switch likeState {
        case .liked:
            try await likeSystemService.removeLikeFromPost(postID: postID)
            try await ActivitySystemService.shared.removeLikeEventForPost(postID: postID, postAuthorID: postAuthorID)
            return .notLiked
        case .notLiked:
            try await likeSystemService.likePost(postID: postID)
            let activityEvent = ActivityEvent.createActivityEventFor(likedPostID: postID)
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
            return try await bookmarksService.removeBookmark(postID: postID)
        case .notBookmarked:
            return try await bookmarksService.bookmarkPost(postID: postID, authorID: authorID)
        }
    }
}
