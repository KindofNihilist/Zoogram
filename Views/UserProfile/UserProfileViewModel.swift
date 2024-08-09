//
//  UserProfileViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.09.2022.
//

import Foundation
import SDWebImage

@MainActor
class UserProfileViewModel {

    let service: any UserProfileServiceProtocol

    var postsCount: Int?
    var followersCount: Int?
    var followedUsersCount: Int?
    var posts = [PostViewModel]()

    private var user: ZoogramUser

    var userID: String {
        return user.userID
    }

    var bio: String? {
        return user.bio
    }

    var name: String {
        return user.name
    }

    var username: String {
        return user.username
    }

    var profileImage: UIImage {
        return user.getProfilePhoto() ?? UIImage.profilePicturePlaceholder
    }

    var isCurrentUserProfile: Bool {
        return user.isCurrentUserProfile
    }

    var followStatus: FollowStatus? {
        return user.followStatus
    }

    init(service: any UserProfileServiceProtocol, user: ZoogramUser) {
        self.user = user
        self.service = service
        self.user = ZoogramUser(service.userID)
        self.postsCount = nil
        self.followersCount = nil
        self.followedUsersCount = nil
    }

    func isPaginationAllowed() async -> Bool {
        return await service.paginationManager.isPaginationAllowed()
    }

    func getPosts() async throws {
        let posts = try await service.getItems()
        if let posts = posts {
            self.posts = posts.compactMap { post in
                return PostViewModel(post: post)
            }
        }
    }

    func getMorePosts() async throws -> [PostViewModel]? {
        let posts = try await service.getMoreItems()
        if let posts = posts {
            let postViewModels = posts.compactMap { post in
                return PostViewModel(post: post)
            }
            self.posts.append(contentsOf: postViewModels)
            return postViewModels
        } else {
            return nil
        }
    }

    func getUserProfileData() async throws {
        async let user = service.getUserData()
        async let followersCount = service.getFollowersCount()
        async let followedUsersCount = service.getFollowingCount()
        async let postsCount = service.getNumberOfItems()

        self.user = try await user
        self.followersCount = try await followersCount
        self.followedUsersCount = try await followedUsersCount
        self.postsCount = try await postsCount
    }

    func updateCurrentUserModel() async {
        guard isCurrentUserProfile else { return }
        let userModel = await UserManager.shared.getCurrentUser()
        self.user = userModel
    }

    func followUser() async throws {
        try await service.followUser()
        self.user.followStatus = .following
    }

    func unfollowUser() async throws {
        try await service.unfollowUser()
        self.user.followStatus = .notFollowing
    }

    func hasHitTheEndOfPosts() async -> Bool {
        return await service.checkIfHasHitEndOfItems()
    }

    func shouldReloadData() async -> Bool {
        return await service.paginationManager.shouldReloadData()
    }
}
