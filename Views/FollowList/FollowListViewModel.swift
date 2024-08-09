//
//  FollowListViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 02.11.2022.
//

import Foundation

@MainActor
class FollowListViewModel {

    let service: FollowListServiceProtocol

    let isUserProfile: Bool

    var userList = [ZoogramUser]()

    init(service: FollowListServiceProtocol, isUserProfile: Bool) {
        self.service = service
        self.isUserProfile = isUserProfile
    }

    func getUserList() async throws -> [ZoogramUser] {
        userList = try await service.getUserList()
        return userList
    }

    func followUser(uid: String) async throws {
        try await service.followUser(uid: uid)
    }

    func unfollowUser(uid: String) async throws {
        try await service.unfollowUser(uid: uid)
    }

    func removeUserFollowingMe(uid: String) async throws {
        try await service.removeUserFollowingMe(uid: uid)
    }

    func undoUserRemoval(uid: String) async throws {
        try await service.undoUserRemoval(uid: uid)
    }
}
