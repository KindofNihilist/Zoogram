//
//  UserSearchService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 08.04.2024.
//

import Foundation

protocol DiscoverServiceProtocol: PostsNetworking<UserPost> {
    func searchUserWith(username: String) async throws -> [ZoogramUser]
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

    func getNumberOfItems() async throws -> Int {
        let postsCount = try await discoverPostsService.getDiscoverPostsCount()
        self.numberOfAllItems = UInt(postsCount)
        return postsCount
    }

    func getItems() async throws -> [UserPost]? {
        _ = try await getNumberOfItems()
        let discoverPosts = try await discoverPostsService.getDiscoverPosts(quantity: numberOfItemsToGet)
        guard discoverPosts.items.isEmpty != true else {
            self.hasHitTheEndOfPosts = true
            return nil
        }
        let postsWithAdditionalData = try await getAdditionalPostDataFor(postsOfMultipleUsers: discoverPosts.items)
        self.lastReceivedItemKey = discoverPosts.lastRetrievedItemKey
        print("last receivedItemKey")
        self.hasHitTheEndOfPosts = false
        self.numberOfRetrievedItems = UInt(discoverPosts.items.count)
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
            let discoverPosts = try await discoverPostsService.getMoreDiscoverPosts(quantity: numberOfItemsToGet, after: lastReceivedItemKey)
            guard discoverPosts.items.isEmpty != true, discoverPosts.lastRetrievedItemKey != self.lastReceivedItemKey else {
                self.isAlreadyPaginating = false
                self.hasHitTheEndOfPosts = true
                return nil
            }
            let postsWithAdditionalData = try await getAdditionalPostDataFor(postsOfMultipleUsers: discoverPosts.items)
            self.lastReceivedItemKey = discoverPosts.lastRetrievedItemKey
            self.numberOfRetrievedItems += UInt(discoverPosts.items.count)
            if self.numberOfRetrievedItems == self.numberOfAllItems {
                self.hasHitTheEndOfPosts = true
            }
            return postsWithAdditionalData
        } catch {
            self.isAlreadyPaginating = false
            throw error
        }
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

    func searchUserWith(username: String) async throws -> [ZoogramUser] {
        let foundUsers = try await userDataService.searchUserWith(username: username)

        for user in foundUsers {
            let userPfp = try await self.getImage(for: user.profilePhotoURL)
            user.setProfilePhoto(userPfp)

        }
        return foundUsers
    }
}
