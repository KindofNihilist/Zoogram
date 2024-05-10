//
//  UserProfileViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.09.2022.
//

import Foundation
import SDWebImage

class UserProfileViewModel {

    private var service: any UserProfileServiceProtocol

    var user: ZoogramUser {
        didSet {
            self.isCurrentUserProfile = user.isCurrentUserProfile
        }
    }

    var isCurrentUserProfile: Bool = false

    var postsCount: Int?
    var followersCount: Int?
    var followedUsersCount: Int?

    var posts: Observable = Observable([PostViewModel]())

    init(service: any UserProfileServiceProtocol, user: ZoogramUser, postsCount: Int, followersCount: Int, followingCount: Int) {
        self.service = service
        self.user = user
        self.postsCount = postsCount
        self.followersCount = followersCount
        self.followedUsersCount = followingCount
        self.isCurrentUserProfile = user.isCurrentUserProfile
    }

    init(service: any UserProfileServiceProtocol) {
        self.service = service
        self.user = ZoogramUser(service.userID)
        self.postsCount = nil
        self.followersCount = nil
        self.followedUsersCount = nil
        self.isCurrentUserProfile = false
    }

    func isPaginationAllowed() -> Bool {
        return service.hasHitTheEndOfPosts == false && service.isAlreadyPaginating == false
    }

    func getPosts() async throws {
        let posts = try await service.getItems()
        if let posts = posts {
            let postViewModels = posts.compactMap { post in
                return PostViewModel(post: post)
            }
            self.posts.value = postViewModels
        }
    }

    func getMorePosts() async throws -> [PostViewModel]? {
        let posts = try await service.getMoreItems()
        if let posts = posts {
            let postViewModels = posts.compactMap { post in
                return PostViewModel(post: post)
            }
            self.posts.value.append(contentsOf: postViewModels)
            return postViewModels
        } else {
            return nil
        }
    }

    func getUserProfileData() async throws {
        async let followersCount = service.getFollowersCount()
        async let followedUsersCount = service.getFollowingCount()
        async let postsCount = service.getNumberOfItems()

        self.followersCount = try await followersCount
        self.followedUsersCount = try await followedUsersCount
        self.postsCount = try await postsCount

        if !isCurrentUserProfile {
            async let user = service.getUserData()
            self.user = try await user
        }
    }

    func followUser() async throws -> FollowStatus {
        let newFollowStatus = try await service.followUser()
        self.user.followStatus = newFollowStatus
        return newFollowStatus
    }

    func unfollowUser() async throws -> FollowStatus {
        let newFollowStatus = try await service.unfollowUser()
        self.user.followStatus = newFollowStatus
        return newFollowStatus
    }

    func hasHitTheEndOfPosts() -> Bool {
        return service.hasHitTheEndOfPosts
    }

    func hasFinishedPaginating() {
        service.isAlreadyPaginating = false
    }

    func hasLoadedData() -> Bool {
        let hasntRetrievedPosts = service.numberOfRetrievedItems == 0
        let numberOfReceivedItemsIsLessThanRequired = service.numberOfRetrievedItems < service.numberOfItemsToGet
        let hasntRetrievedAllPosts = service.numberOfRetrievedItems < service.numberOfAllItems
        let retrievedLessPostsThanRequired = numberOfReceivedItemsIsLessThanRequired && hasntRetrievedAllPosts

        if hasntRetrievedPosts || retrievedLessPostsThanRequired {
            return false
        } else {
            return true
        }
    }
}
