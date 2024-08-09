//
//  UserProfileService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.04.2023.
//

import Foundation

protocol UserProfileServiceProtocol: PostsNetworking<UserPost> {
    var userID: String { get }

    var followService: FollowSystemProtocol { get }
    var userPostsService: UserPostsServiceProtocol { get }
    var userDataService: UserDataServiceProtocol { get }
    var likeSystemService: LikeSystemServiceProtocol { get }
    var bookmarksService: BookmarksSystemServiceProtocol { get }
    var activityService: ActivitySystemProtocol { get }
    var imageService: ImageServiceProtocol { get }

    func getFollowersCount() async throws -> Int
    func getFollowingCount() async throws -> Int
    func getUserData() async throws -> ZoogramUser
    func followUser() async throws
    func unfollowUser() async throws
}

final class UserProfileService: UserProfileServiceProtocol {

    internal let paginationManager = PaginationManager(numberOfItemsToGetPerPagination: 12)

    let userID: String

    internal let followService: FollowSystemProtocol
    internal let userPostsService: UserPostsServiceProtocol
    internal let userDataService: UserDataServiceProtocol
    internal let likeSystemService: LikeSystemServiceProtocol
    internal let bookmarksService: BookmarksSystemServiceProtocol
    internal let activityService: ActivitySystemProtocol
    internal let imageService: ImageServiceProtocol
    internal let commentsService: CommentSystemServiceProtocol

    init(userID: String,
         followService: FollowSystemProtocol,
         userPostsService: UserPostsServiceProtocol,
         userService: UserDataServiceProtocol,
         likeSystemService: LikeSystemServiceProtocol,
         bookmarksService: BookmarksSystemServiceProtocol,
         activityService: ActivitySystemProtocol,
         imageService: ImageServiceProtocol,
         commentsService: CommentSystemServiceProtocol) {
        self.userID = userID
        self.followService = followService
        self.userPostsService = userPostsService
        self.userDataService = userService
        self.likeSystemService = likeSystemService
        self.bookmarksService = bookmarksService
        self.activityService = activityService
        self.imageService = imageService
        self.commentsService = commentsService
    }

    func getFollowersCount() async throws -> Int {
        return try await followService.getFollowersNumber(for: userID)
    }

    func getFollowingCount() async throws -> Int {
        return try await followService.getFollowingNumber(for: userID)
    }

    func getUserData() async throws -> ZoogramUser {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()

        if userID == currentUserID {
            return await UserManager.shared.getCurrentUser()
        } else {
            var user = try await userDataService.getUser(for: userID)
            if let profilePhotoURL = user.profilePhotoURL {
                let profilePicture = try await imageService.getImage(for: profilePhotoURL)
                user.setProfilePhoto(profilePicture)
            }
            return user
        }
    }

    func getNumberOfItems() async throws -> Int {
        let numberOfAllItems = try await userPostsService.getPostCount(for: userID)
        await paginationManager.setNumberOfAllItems(numberOfAllItems)
        return numberOfAllItems
    }

    func getItems() async throws -> [UserPost]? {
        do {
            guard await paginationManager.isPaginating() == false else { return nil }
            await paginationManager.startPaginating()
            let numberOfItemsToGet = paginationManager.numberOfItemsToGetPerPagination
            async let numberOfAllItems = getNumberOfItems()
            async let retrievedPosts = userPostsService.getPosts(quantity: numberOfItemsToGet, for: userID)

            guard try await retrievedPosts.items.isEmpty != true else {
                await paginationManager.finishPaginating()
                return nil
            }

            let postsWithAdditionalData = try await getAdditionalPostDataFor(postsOfSingleUser: retrievedPosts.items)
            let lastRetrievedItemKey = try await retrievedPosts.lastRetrievedItemKey
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
            let paginatedPosts = try await userPostsService.getMorePosts(quantity: numberOfItemsToGet, after: lastReceivedItemKey, for: userID)

            guard paginatedPosts.items.isEmpty != true, paginatedPosts.lastRetrievedItemKey != lastReceivedItemKey else {
                await paginationManager.finishPaginating()
                return nil
            }

            let postsWithAdditionalData = try await getAdditionalPostDataFor(postsOfSingleUser: paginatedPosts.items)
            await paginationManager.setLastReceivedItemKey(paginatedPosts.lastRetrievedItemKey)
            await paginationManager.updateNumberOfRetrievedItems(value: paginatedPosts.items.count)
            await paginationManager.finishPaginating()
            return postsWithAdditionalData
        } catch {
            await paginationManager.finishPaginating()
            throw error
        }
    }

    func followUser() async throws {
        try await followService.followUser(uid: userID)
    }

    func unfollowUser() async throws {
        try await followService.unfollowUser(uid: userID)
    }

    func likePost(postID: String, likeState: LikeState, postAuthorID: String) async throws {
        switch likeState {
        case .liked:
            async let likeRemovalTask: Void = likeSystemService.removeLikeFromPost(postID: postID)
            async let activityRemovalTask: Void = activityService.removeLikeEventForPost(postID: postID, postAuthorID: postAuthorID)
            _ = try await [likeRemovalTask, activityRemovalTask]
        case .notLiked:
            let activityEvent = ActivityEvent.createActivityEventFor(likedPostID: postID)
            async let likeTask: Void = likeSystemService.likePost(postID: postID)
            async let activityEventTask: Void = activityService.addEventToUserActivity(event: activityEvent, userID: postAuthorID)
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
