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

    internal let searchService: SearchServiceProtocol
    internal let discoverPostsService: DiscoverPostsServiceProtocol
    internal let likeSystemService: LikeSystemServiceProtocol
    internal let userPostsService: UserPostsServiceProtocol
    internal let bookmarksService: BookmarksSystemServiceProtocol
    internal let userDataService: UserDataServiceProtocol
    internal let imageService: any ImageServiceProtocol
    internal let commentsService: any CommentSystemServiceProtocol

    init(searchService: SearchServiceProtocol,
         userDataService: UserDataServiceProtocol,
         discoverPostsService: DiscoverPostsServiceProtocol,
         likeSystemService: LikeSystemServiceProtocol,
         userPostsService: UserPostsServiceProtocol,
         bookmarksService: BookmarksSystemServiceProtocol,
         imageService: ImageServiceProtocol,
         commentsService: CommentSystemServiceProtocol) {
        self.searchService = searchService
        self.discoverPostsService = discoverPostsService
        self.likeSystemService = likeSystemService
        self.userPostsService = userPostsService
        self.bookmarksService = bookmarksService
        self.userDataService = userDataService
        self.imageService = imageService
        self.commentsService = commentsService
    }

    func getNumberOfItems() async throws -> Int {
        let postsCount = try await discoverPostsService.getDiscoverPostsCount()
        await paginationManager.setNumberOfAllItems(postsCount)
        return postsCount
    }

    func getItems() async throws -> [UserPost]? {
        do {
            guard await paginationManager.isPaginating() == false else { return nil }
            await self.paginationManager.startPaginating()

            let numberOfItemsToGet = paginationManager.numberOfItemsToGetPerPagination
            async let numberOfAllItems = getNumberOfItems()
            async let discoverPosts = discoverPostsService.getDiscoverPosts(quantity: numberOfItemsToGet)

            guard try await discoverPosts.items.isEmpty != true else {
                await paginationManager.finishPaginating()
                return nil
            }

            let postsWithAdditionalData = try await getAdditionalPostDataFor(postsOfMultipleUsers: discoverPosts.items)
            let lastRetrievedItemKey = try await discoverPosts.lastRetrievedItemKey
            await paginationManager.setLastReceivedItemKey(lastRetrievedItemKey)
            await paginationManager.resetNumberOfRetrievedItems()
            await paginationManager.updateNumberOfRetrievedItems(value: postsWithAdditionalData.count)
            await paginationManager.finishPaginating()
            return postsWithAdditionalData
        } catch {
            await paginationManager.finishPaginating()
            throw error
        }
    }

    func getMoreItems() async throws -> [UserPost]? {
        do {
            let isPaginating = await paginationManager.isPaginating()
            let lastReceivedItemKey = await paginationManager.getLastReceivedItemKey()
            guard isPaginating == false, lastReceivedItemKey != "" else { return nil }
            await paginationManager.startPaginating()

            let numberOfItemsToGet = paginationManager.numberOfItemsToGetPerPagination
            let discoverPosts = try await discoverPostsService.getMoreDiscoverPosts(quantity: numberOfItemsToGet, after: lastReceivedItemKey)

            guard discoverPosts.items.isEmpty != true, discoverPosts.lastRetrievedItemKey != lastReceivedItemKey else {
                await paginationManager.finishPaginating()
                return nil
            }

            let postsWithAdditionalData = try await getAdditionalPostDataFor(postsOfMultipleUsers: discoverPosts.items)
            await paginationManager.setLastReceivedItemKey(discoverPosts.lastRetrievedItemKey)
            await paginationManager.updateNumberOfRetrievedItems(value: discoverPosts.items.count)
            await paginationManager.finishPaginating()
            return postsWithAdditionalData
        } catch {
            await paginationManager.finishPaginating()
            throw error
        }
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

    func searchUserWith(username: String) async throws -> [ZoogramUser] {
        let foundUsersIDs = try await searchService.searchUserWith(partialString: username)
        var foundUsers = [ZoogramUser?](repeating: nil, count: foundUsersIDs.count)
        try await withThrowingTaskGroup(of: (Int, ZoogramUser).self) { group in
            for (index, userID) in foundUsersIDs.enumerated() {
                group.addTask {
                    var foundUser = try await self.userDataService.getUser(for: userID)
                    let userPfp = try await ImageService.shared.getImage(for: foundUser.profilePhotoURL)
                    foundUser.setProfilePhoto(userPfp)
                    return (index, foundUser)
                }
            }

            for try await (index, user) in group {
                foundUsers[index] = user
            }
        }
        return foundUsers.compactMap { $0 }
    }
}
