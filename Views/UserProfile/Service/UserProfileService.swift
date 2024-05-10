//
//  UserProfileService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.04.2023.
//

import Foundation

protocol UserProfileServiceProtocol: PostsNetworking<UserPost> {
    var userID: String { get }
    var dispatchGroup: DispatchGroup { get set }

    var followService: FollowSystemProtocol { get }
    var userPostsService: UserPostsServiceProtocol { get }
    var userDataService: UserDataServiceProtocol { get }
    var likeSystemService: LikeSystemServiceProtocol { get }
    var bookmarksService: BookmarksSystemServiceProtocol { get }

    func getFollowersCount() async throws -> Int
    func getFollowingCount() async throws -> Int
    func getUserData() async throws -> ZoogramUser
    func followUser() async throws -> FollowStatus
    func unfollowUser() async throws -> FollowStatus
}

typealias HasHitTheEnd = Bool

class UserProfileService: ImageService, UserProfileServiceProtocol {

    var numberOfRetrievedItems: UInt = 0
    var numberOfAllItems: UInt = 0
    var numberOfItemsToGet: UInt = 12
    var lastReceivedItemKey: String = ""
    var isAlreadyPaginating: Bool = false
    var hasHitTheEndOfPosts: HasHitTheEnd = false

    var userID: String

    let followService: FollowSystemProtocol
    let userPostsService: UserPostsServiceProtocol
    let userDataService: UserDataServiceProtocol
    let likeSystemService: LikeSystemServiceProtocol
    let bookmarksService: BookmarksSystemServiceProtocol

    var dispatchGroup = DispatchGroup()

    init(userID: String,
         followService: FollowSystemProtocol,
         userPostsService: UserPostsServiceProtocol,
         userService: UserDataServiceProtocol,
         likeSystemService: LikeSystemServiceProtocol,
         bookmarksService: BookmarksSystemServiceProtocol) {
        self.userID = userID
        self.followService = followService
        self.userPostsService = userPostsService
        self.userDataService = userService
        self.likeSystemService = likeSystemService
        self.bookmarksService = bookmarksService
        self.dispatchGroup = DispatchGroup()
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
            return UserManager.shared.getCurrentUser()
        } else {
            let user = try await userDataService.getUser(for: userID)
            if let profilePhotoURL = user.profilePhotoURL {
                let profilePicture = try await getImage(for: profilePhotoURL)
                user.setProfilePhoto(profilePicture)
            }
            return user
        }
    }

    func getNumberOfItems() async throws -> Int {
        return try await userPostsService.getPostCount(for: userID)
    }

    func getItems() async throws -> [UserPost]? {
        let paginatedPosts = try await userPostsService.getPosts(quantity: numberOfItemsToGet, for: userID)

        guard paginatedPosts.items.isEmpty != true else {
            self.hasHitTheEndOfPosts = true
            return nil
        }

        let postsWithAdditionalData = try await getAdditionalPostDataFor(postsOfSingleUser: paginatedPosts.items)
        self.lastReceivedItemKey = paginatedPosts.lastRetrievedItemKey
        self.hasHitTheEndOfPosts = false
        self.numberOfRetrievedItems = UInt(paginatedPosts.items.count)
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
            let paginatedPosts = try await userPostsService.getMorePosts(quantity: numberOfItemsToGet, after: lastReceivedItemKey, for: userID)

            guard paginatedPosts.items.isEmpty != true, paginatedPosts.lastRetrievedItemKey != self.lastReceivedItemKey else {
                self.hasHitTheEndOfPosts = true
                self.isAlreadyPaginating = false
                return nil
            }

            let postsWithAdditionalData = try await getAdditionalPostDataFor(postsOfSingleUser: paginatedPosts.items)
            self.numberOfRetrievedItems += UInt(paginatedPosts.items.count)
            self.lastReceivedItemKey = paginatedPosts.lastRetrievedItemKey
            if self.numberOfRetrievedItems == self.numberOfAllItems {
                self.hasHitTheEndOfPosts = true
            }
            return postsWithAdditionalData
        } catch {
            self.isAlreadyPaginating = false
            throw error
        }
    }

    func followUser() async throws -> FollowStatus {
        return try await followService.followUser(uid: userID)
    }

    func unfollowUser() async throws -> FollowStatus {
        return try await followService.unfollowUser(uid: userID)
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

func createUserProfileDefaultServiceFor(userID: String) -> UserProfileService {
    UserProfileService(userID: userID,
                       followService: FollowSystemService.shared,
                       userPostsService: UserPostsService.shared,
                       userService: UserDataService.shared,
                       likeSystemService: LikeSystemService.shared,
                       bookmarksService: BookmarksSystemService.shared)
}

