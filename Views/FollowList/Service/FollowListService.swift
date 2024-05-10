//
//  FollowListService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 29.01.2024.
//

import Foundation
import SDWebImage

protocol FollowListServiceProtocol {
    var followSystemService: FollowSystemProtocol { get }
    func getUserList() async throws -> [ZoogramUser]
    func followUser(uid: String) async throws -> FollowStatus
    func unfollowUser(uid: String) async throws -> FollowStatus
    func removeUserFollowingMe(uid: String) async throws
    func undoUserRemoval(uid: String) async throws
}

class FollowedListService: ImageService, FollowListServiceProtocol {

    var followSystemService: FollowSystemProtocol

    let userID: String

    init(for userID: UserID, followSystemService: FollowSystemProtocol) {
        self.userID = userID
        self.followSystemService = followSystemService
    }

    func getUserList() async throws -> [ZoogramUser] {
        let followedUsers = try await followSystemService.getFollowing(for: userID)
        for followedUser in followedUsers {
            if let profilePhotoURL = followedUser.profilePhotoURL {
                let profilePhoto = try await getImage(for: profilePhotoURL)
                followedUser.setProfilePhoto(profilePhoto)
            }
        }
        return followedUsers
    }

    func followUser(uid: String) async throws -> FollowStatus {
        return try await followSystemService.followUser(uid: uid)
    }

    func unfollowUser(uid: String) async throws -> FollowStatus {
        return try await followSystemService.unfollowUser(uid: uid)
    }

    func removeUserFollowingMe(uid: String) async throws {
        try await followSystemService.forcefullyRemoveFollower(uid: uid)
    }

    func undoUserRemoval(uid: String) async throws {
        try await followSystemService.undoForcefullRemoval(ofUser: uid)
    }
}

class FollowersListService: FollowedListService {

    override func getUserList() async throws -> [ZoogramUser] {
        let followedUsers = try await followSystemService.getFollowers(for: userID)
        for followedUser in followedUsers {
            if let profilePhotoURL = followedUser.profilePhotoURL {
                let profilePhoto = try await getImage(for: profilePhotoURL)
                followedUser.setProfilePhoto(profilePhoto)
            }
        }
        return followedUsers
    }
}
