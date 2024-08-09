//
//  FollowersListService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 10.06.2024.
//

import Foundation

final class FollowersListService: FollowListServiceProtocol {

    let followSystemService: FollowSystemProtocol
    let userDataService: UserDataServiceProtocol

    let userID: String

    init(for userID: UserID, followSystemService: FollowSystemProtocol, userDataService: UserDataServiceProtocol) {
        self.userID = userID
        self.followSystemService = followSystemService
        self.userDataService = userDataService
    }

    func getUserList() async throws -> [ZoogramUser] {
        let followersIDs = try await followSystemService.getFollowers(for: userID)
        let followers = try await withThrowingTaskGroup(of: (Int, ZoogramUser).self, returning: [ZoogramUser].self) { group in
            for (index, userID) in followersIDs.enumerated() {
                group.addTask {
                    var followerUserProfileData = try await self.userDataService.getUser(for: userID)
                    let profilePhoto = try await ImageService.shared.getImage(for: followerUserProfileData.profilePhotoURL)
                    followerUserProfileData.setProfilePhoto(profilePhoto)
                    return (index, followerUserProfileData)
                }
            }
            var followers = [ZoogramUser?](repeating: nil, count: followersIDs.count)
            for try await (index, user) in group {
                followers[index] = user
            }
            return followers.compactMap { $0 }
        }
        return followers
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
