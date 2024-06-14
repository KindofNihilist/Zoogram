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

final class DiscoverService: DiscoverServiceProtocol {

    internal let paginationManager = PaginationManager(numberOfItemsToGetPerPagination: 18)

    let searchService: SearchServiceProtocol
    let discoverPostsService: DiscoverPostsServiceProtocol
    let likeSystemService: LikeSystemServiceProtocol
    let userPostsService: UserPostsServiceProtocol
    let bookmarksService: BookmarksSystemServiceProtocol

    init(searchService: SearchServiceProtocol,
         discoverPostsService: DiscoverPostsServiceProtocol,
         likeSystemService: LikeSystemServiceProtocol,
         userPostsService: UserPostsServiceProtocol,
         bookmarksService: BookmarksSystemServiceProtocol) {
        self.searchService = searchService
        self.discoverPostsService = discoverPostsService
        self.likeSystemService = likeSystemService
        self.userPostsService = userPostsService
        self.bookmarksService = bookmarksService
    }

    func getNumberOfItems() async throws -> Int {
        let postsCount = try await discoverPostsService.getDiscoverPostsCount()
        await paginationManager.setNumberOfAllItems(postsCount)
        return postsCount
    }

    func getItems() async throws -> [UserPost]? {
        let isPaginating = await self.paginationManager.isPaginating()
        guard isPaginating == false else { return nil }
        await self.paginationManager.startPaginating()

        let numberOfItemsToGet = paginationManager.numberOfItemsToGetPerPagination
        async let numberOfAllItems = getNumberOfItems()
        async let discoverPosts = discoverPostsService.getDiscoverPosts(quantity: numberOfItemsToGet)

        guard try await discoverPosts.items.isEmpty != true else {
            await paginationManager.setHasHitEndOfItemsStatus(to: true)
            await paginationManager.finishPaginating()
            return nil
        }

        let postsWithAdditionalData = try await getAdditionalPostDataFor(postsOfMultipleUsers: discoverPosts.items)
        let lastRetrievedItemKey = try await discoverPosts.lastRetrievedItemKey
        await paginationManager.setLastReceivedItemKey(lastRetrievedItemKey)
        await paginationManager.setHasHitEndOfItemsStatus(to: false)
        await paginationManager.updateNumberOfRetrievedItems(value: postsWithAdditionalData.count)

        let numberOfRetrievedItems = await paginationManager.getNumberOfRetrievedItems()
        if try await numberOfRetrievedItems == numberOfAllItems {
            await paginationManager.setHasHitEndOfItemsStatus(to: true)
        }
        await paginationManager.finishPaginating()
        return postsWithAdditionalData
    }

    func getMoreItems() async throws -> [UserPost]? {
        let isPaginating = await paginationManager.isPaginating()
        let lastReceivedItemKey = await paginationManager.getLastReceivedItemKey()
        guard isPaginating == false, lastReceivedItemKey != "" else { return nil }
        await paginationManager.startPaginating()

        let numberOfItemsToGet = paginationManager.numberOfItemsToGetPerPagination
        let discoverPosts = try await discoverPostsService.getMoreDiscoverPosts(quantity: numberOfItemsToGet, after: lastReceivedItemKey)

        guard discoverPosts.items.isEmpty != true, discoverPosts.lastRetrievedItemKey != lastReceivedItemKey else {
            await paginationManager.finishPaginating()
            await paginationManager.setHasHitEndOfItemsStatus(to: true)
            return nil
        }

        let postsWithAdditionalData = try await getAdditionalPostDataFor(postsOfMultipleUsers: discoverPosts.items)
        await paginationManager.setLastReceivedItemKey(discoverPosts.lastRetrievedItemKey)
        await paginationManager.updateNumberOfRetrievedItems(value: discoverPosts.items.count)
        let numberOfRetrievedItems = await paginationManager.getNumberOfRetrievedItems()
        let numberOfAllItems = await paginationManager.getNumberOfAllItems()
        if numberOfRetrievedItems == numberOfAllItems {
            await paginationManager.setHasHitEndOfItemsStatus(to: true)
        }
        await paginationManager.finishPaginating()
        return postsWithAdditionalData
    }

    func likePost(postID: String, likeState: LikeState, postAuthorID: String) async throws {
        switch likeState {
        case .liked:
            try await likeSystemService.removeLikeFromPost(postID: postID)
            try await ActivitySystemService.shared.removeLikeEventForPost(postID: postID, postAuthorID: postAuthorID)
        case .notLiked:
            try await likeSystemService.likePost(postID: postID)
            let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
            let eventID = ActivitySystemService.shared.createEventUID()
            let activityEvent = ActivityEvent(eventType: .postLiked, userID: currentUserID, postID: postID, eventID: eventID, date: Date())
            try await ActivitySystemService.shared.addEventToUserActivity(event: activityEvent, userID: postAuthorID)
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

    func searchUserWith(username: String) async throws -> [ZoogramUser] {
        var foundUsers = try await searchService.searchUserWith(username: username)
        try await withThrowingTaskGroup(of: (Int, ZoogramUser).self) { group in
            for (index, user) in foundUsers.enumerated() {
                group.addTask {
                    var foundUser = user
                    let userPfp = try await ImageService.shared.getImage(for: user.profilePhotoURL)
                    foundUser.setProfilePhoto(userPfp)
                    return (index, foundUser)
                }
            }

            for try await (index, user) in group {
                foundUsers[index] = user
            }
        }
        return foundUsers
    }
}
