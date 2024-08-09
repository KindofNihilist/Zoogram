//
//  FollowSystemMock.swift
//  ZoogramTests
//
//  Created by Artem Dolbiiev on 10.07.2024.
//

import Foundation
@testable import Zoogram

final class FollowSystemMock: FollowSystemProtocol {
    func getFollowersNumber(for uid: String) async throws -> FollowersNumber {
        return 0
    }
    
    func getFollowingNumber(for uid: String) async throws -> FollowingNumber {
        return 0
    }
    
    func getFollowers(for uid: String) async throws -> [Zoogram.UserID] {
        return []
    }
    
    func getFollowing(for uid: String) async throws -> [Zoogram.UserID] {
        return []
    }
    
    func checkFollowStatus(for uid: String) async throws -> Zoogram.FollowStatus {
        return .following
    }
    
    func followUser(uid: String) async throws {
        return
    }
    
    func unfollowUser(uid: String) async throws {
        return
    }
    
    func insertFollower(with uid: String, to user: String) async throws {
        return
    }
    
    func removeFollower(with uid: String, from user: String) async throws {
        return
    }
    
    func forcefullyRemoveFollower(uid: String) async throws {
        return
    }
    
    func undoForcefullRemoval(ofUser uid: String) async throws {
        return
    }
}
