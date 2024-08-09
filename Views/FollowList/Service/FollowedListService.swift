//
//  FollowListService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 29.01.2024.
//

import Foundation

protocol FollowListServiceProtocol: Sendable {
    var followSystemService: FollowSystemProtocol { get }
    func getUserList() async throws -> [ZoogramUser]
    func followUser(uid: String) async throws
    func unfollowUser(uid: String) async throws
    func removeUserFollowingMe(uid: String) async throws
    func undoUserRemoval(uid: String) async throws
}

final class FollowedListService: FollowListServiceProtocol {

    let followSystemService: FollowSystemProtocol
    let userDataService: UserDataServiceProtocol

    let userID: String

    init(for userID: UserID, followSystemService: FollowSystemProtocol, userDataService: UserDataServiceProtocol) {
        self.userID = userID
        self.followSystemService = followSystemService
        self.userDataService = userDataService
    }

    func getUserList() async throws -> [ZoogramUser] {
        let followedUsersIDs = try await followSystemService.getFollowing(for: userID)
        let followedUsers = try await withThrowingTaskGroup(of: (Int, ZoogramUser).self, returning: [ZoogramUser].self) { group in
            for (index, userID) in followedUsersIDs.enumerated() {
                group.addTask {
                    var followedUserProfileData = try await self.userDataService.getUser(for: userID)
                    let profilePhoto = try await ImageService.shared.getImage(for: followedUserProfileData.profilePhotoURL)
                    followedUserProfileData.setProfilePhoto(profilePhoto)
                    return (index, followedUserProfileData)
                }
            }
            var followedUsers = [ZoogramUser?](repeating: nil, count: followedUsersIDs.count)
            for try await (index, user) in group {
                followedUsers[index] = user
            }
            return followedUsers.compactMap { $0 }
        }
        return followedUsers
    }

    func followUser(uid: String) async throws {
        try await followSystemService.followUser(uid: uid)
    }

    func unfollowUser(uid: String) async throws {
        try await followSystemService.unfollowUser(uid: uid)
    }

    func removeUserFollowingMe(uid: String) async throws {
        try await followSystemService.forcefullyRemoveFollower(uid: uid)
    }

    func undoUserRemoval(uid: String) async throws {
        try await followSystemService.undoForcefullRemoval(ofUser: uid)
    }
}
