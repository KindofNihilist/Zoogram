//
//  FollowService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.12.2022.
//

import Foundation
@preconcurrency import FirebaseDatabase

protocol FollowSystemProtocol: Sendable {
    typealias FollowersNumber = Int
    typealias FollowingNumber = Int
    func getFollowersNumber(for uid: String) async throws -> FollowersNumber
    func getFollowingNumber(for uid: String) async throws -> FollowingNumber
    func getFollowers(for uid: String) async throws -> [UserID]
    func getFollowing(for uid: String) async throws -> [UserID]
    func checkFollowStatus(for uid: String) async throws -> FollowStatus
    func followUser(uid: String) async throws -> FollowStatus
    func unfollowUser(uid: String) async throws -> FollowStatus
    func insertFollower(with uid: String, to user: String) async throws
    func removeFollower(with uid: String, from user: String) async throws
    func forcefullyRemoveFollower(uid: String) async throws
    func undoForcefullRemoval(ofUser uid: String) async throws
}

final class FollowSystemService: FollowSystemProtocol {

    static let shared = FollowSystemService()

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    func getFollowersNumber(for uid: String) async throws -> FollowersNumber {
        let databaseKey =  "Followers/\(uid)"

        do {
            let data = try await databaseRef.child(databaseKey).getData()
            return Int(data.childrenCount)
        } catch {
            throw ServiceError.couldntLoadData
        }
    }

    func getFollowingNumber(for uid: String) async throws -> FollowingNumber {
        let databaseKey =  "Following/\(uid)"

        do {
            let data = try await databaseRef.child(databaseKey).getData()
            return Int(data.childrenCount)
        } catch {
            throw ServiceError.couldntLoadData
        }
    }

    func getFollowers(for uid: String) async throws -> [UserID] {
        var followers = [UserID]()
        let databaseKey = "Followers/\(uid)"

        do {
            let data = try await databaseRef.child(databaseKey).getData()

            for snapshot in data.children {
                guard let snapshotChild = snapshot as? DataSnapshot,
                      let snapshotDictionary = snapshotChild.value as? [String: String],
                      let userID = snapshotDictionary.first?.value
                else {
                    throw ServiceError.snapshotCastingError
                }
                followers.append(userID)
            }
            return followers
        } catch {
            print(error.localizedDescription)
            throw ServiceError.couldntLoadData
        }
    }

    func getFollowing(for uid: String) async throws -> [UserID] {
        var followedUsers = [UserID]()
        let databaseKey = "Following/\(uid)"

        do {
            let data = try await databaseRef.child(databaseKey).getData()

            for snapshot in data.children {
                guard let snapshotChild = snapshot as? DataSnapshot,
                      let snapshotDictionary = snapshotChild.value as? [String: String],
                      let userID = snapshotDictionary.first?.value
                else {
                    throw ServiceError.snapshotCastingError
                }
                print("followed user: ", snapshot)
                print("userID: ", userID)
                followedUsers.append(userID)
            }
            return followedUsers
        } catch {
            print("getFollowing error: ", error.localizedDescription)
            throw ServiceError.couldntLoadData
        }
    }

    func checkFollowStatus(for uid: String) async throws -> FollowStatus {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let query = databaseRef.child("Following/\(currentUserID)").queryOrdered(byChild: "userID").queryEqual(toValue: uid)

        do {
            let data = try await query.getData()

            if data.exists() {
                return .following
            } else {
                return .notFollowing
            }
        } catch {
            throw ServiceError.couldntLoadData
        }
    }

    func followUser(uid: String) async throws -> FollowStatus {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let databaseKey = "Following/\(currentUserID)/\(uid)"

        do {
            try await databaseRef.child(databaseKey).setValue(["userID": uid])
            try await insertFollower(with: currentUserID, to: uid)

            let eventID = ActivitySystemService.shared.createEventUID()
            let activityEvent = ActivityEvent(eventType: .followed, userID: currentUserID, eventID: eventID, date: Date())
            try await ActivitySystemService.shared.addEventToUserActivity(event: activityEvent, userID: uid)
            return .following
        } catch {
            throw ServiceError.couldntCompleteTheAction
        }
    }

    func unfollowUser(uid: String) async throws -> FollowStatus {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let databaseKey = "Following/\(currentUserID)/\(uid)"

        do {
            try await databaseRef.child(databaseKey).removeValue()
            try await removeFollower(with: currentUserID, from: uid)
            try await ActivitySystemService.shared.removeFollowEventForUser(userID: uid)
            return .notFollowing
        } catch {
            throw ServiceError.couldntCompleteTheAction
        }
    }

    func insertFollower(with uid: String, to user: String) async throws {
        let databaseKey = "Followers/\(user)/\(uid)"
        try await databaseRef.child(databaseKey).setValue(["userID": uid])
    }

    func removeFollower(with uid: String, from user: String) async throws {
        let databaseKey = "Followers/\(user)/\(uid)"
        try await databaseRef.child(databaseKey).removeValue()
    }

    func forcefullyRemoveFollower(uid: String) async throws {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let databaseKey = "Following/\(uid)/\(currentUserID)"

        do {
            try await databaseRef.child(databaseKey).removeValue()
            try await removeFollower(with: uid, from: currentUserID)
        } catch {
            throw ServiceError.couldntCompleteTheAction
        }
    }

    func undoForcefullRemoval(ofUser uid: String) async throws {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let databaseKey = "Following/\(uid)/\(currentUserID)"

        do {
            try await databaseRef.child(databaseKey).setValue(["userID": currentUserID])
            try await insertFollower(with: uid, to: currentUserID)
        } catch {
            throw ServiceError.couldntCompleteTheAction
        }
    }
}
