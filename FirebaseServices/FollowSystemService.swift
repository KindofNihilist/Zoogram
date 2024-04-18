//
//  FollowService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.12.2022.
//

import Foundation
import FirebaseDatabase

protocol FollowSystemProtocol {
    typealias FollowersNumber = Int
    typealias FollowingNumber = Int
    
    func getFollowersNumber(for uid: String, completion: @escaping (Result<FollowersNumber, Error>) -> Void)
    func getFollowingNumber(for uid: String, completion: @escaping (Result<FollowingNumber, Error>) -> Void)
    func getFollowers(for uid: String, completion: @escaping (Result<[ZoogramUser], Error>) -> Void)
    func getFollowing(for uid: String, completion: @escaping (Result<[ZoogramUser], Error>) -> Void)
    func checkFollowStatus(for uid: String, completion: @escaping (Result<FollowStatus, Error>) -> Void)
    func followUser(uid: String, completion: @escaping (Result<FollowStatus, Error>) -> Void)
    func unfollowUser(uid: String, completion: @escaping (Result<FollowStatus, Error>) -> Void)
    func insertFollower(with uid: String, to user: String, completion: @escaping (VoidResult) -> Void)
    func removeFollower(with uid: String, from user: String, completion: @escaping (VoidResult) -> Void)
    func forcefullyRemoveFollower(uid: String, completion: @escaping (VoidResult) -> Void)
    func undoForcefullRemoval(ofUser uid: String, completion: @escaping (VoidResult) -> Void)
}

class FollowSystemService: FollowSystemProtocol {

    static let shared = FollowSystemService()

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    func getFollowersNumber(for uid: String, completion: @escaping (Result<FollowersNumber, Error>) -> Void) {
        let databaseKey =  "Followers/\(uid)"

        databaseRef.child(databaseKey).getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadData))
                return
            } else if let snapshot = snapshot {
                let numberOfFollowers = Int(snapshot.childrenCount)
                completion(.success(numberOfFollowers))
            }
        }
    }

    func getFollowingNumber(for uid: String, completion: @escaping (Result<FollowersNumber, Error>) -> Void) {
        let databaseKey =  "Following/\(uid)"

        databaseRef.child(databaseKey).getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadData))
                return
            } else if let snapshot = snapshot {
                let numberOfFollowing = Int(snapshot.childrenCount)
                completion(.success(numberOfFollowing))
            }
        }
    }

    func getFollowers(for uid: String, completion: @escaping (Result<[ZoogramUser], Error>) -> Void) {
        var followers = [ZoogramUser]()
        let databaseKey = "Followers/\(uid)"
        let dispatchGroup = DispatchGroup()
        var serviceError: Error?

        databaseRef.child(databaseKey).getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadData))
                return
            } else if let snapshot = snapshot {

                for snapshotChild in snapshot.children {
                    guard let snapshotChild = snapshotChild as? DataSnapshot,
                          let snapshotDictionary = snapshotChild.value as? [String : String],
                          let userID = snapshotDictionary.first?.value
                    else {
                        completion(.failure(ServiceError.snapshotCastingError))
                        break
                    }
                    dispatchGroup.enter()
                    UserDataService.shared.getUser(for: userID) { result in
                        switch result {
                        case .success(let follower):
                            followers.append(follower)
                        case .failure(let error):
                            serviceError = ServiceError.couldntLoadData
                            completion(.failure(ServiceError.couldntLoadData))
                            break
                        }
                        dispatchGroup.leave()
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    if let error = serviceError {
                        completion(.failure(error))
                    } else {
                        completion(.success(followers))
                    }
                }
            }
        }
    }

    func getFollowing(for uid: String, completion: @escaping (Result<[ZoogramUser], Error>) -> Void) {
        var followedUsers = [ZoogramUser]()
        let databaseKey = "Following/\(uid)"
        let dispatchGroup = DispatchGroup()
        var serviceError: Error?

        databaseRef.child(databaseKey).getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadData))
                return
            } else if let snapshot = snapshot {

                for snapshotChild in snapshot.children {
                    guard let snapshotChild = snapshotChild as? DataSnapshot,
                          let snapshotDictionary = snapshotChild.value as? [String: String],
                          let userID = snapshotDictionary.first?.value
                    else {
                        completion(.failure(ServiceError.snapshotCastingError))
                        break
                    }
                    dispatchGroup.enter()
                    UserDataService.shared.getUser(for: userID) { result in
                        switch result {
                        case .success(let followedUser):
                            followedUsers.append(followedUser)
                        case .failure(let error):
                            serviceError = ServiceError.couldntLoadData
                            completion(.failure(ServiceError.couldntLoadData))
                            break
                        }
                        dispatchGroup.leave()
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    if let error = serviceError {
                        completion(.failure(error))
                    } else {
                        completion(.success(followedUsers))
                    }
                }
            }
        }
    }

    func checkFollowStatus(for uid: String, completion: @escaping (Result<FollowStatus, Error>) -> Void) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }

        let query = databaseRef.child("Following/\(currentUserID)").queryOrdered(byChild: "userID").queryEqual(toValue: uid)

        query.getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadData))
                return
            } else if let snapshot = snapshot {
                
                if snapshot.exists() {
                    completion(.success(.following))
                } else {
                    completion(.success(.notFollowing))
                }
            }
        }
    }

    func followUser(uid: String, completion: @escaping (Result<FollowStatus, Error>) -> Void) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }
        let databaseKey = "Following/\(currentUserID)/\(uid)"

        databaseRef.child(databaseKey).setValue(["userID": uid]) { error, _ in
            if let error = error {
                completion(.failure(ServiceError.couldntCompleteTheAction))
            } else {
                self.insertFollower(with: currentUserID, to: uid) { result in
                    switch result {
                    case .success:
                        completion(.success(.following))
                    case .failure(let error):
                        completion(.failure(ServiceError.couldntCompleteTheAction))
                    }
                }
                let eventID = ActivitySystemService.shared.createEventUID()
                let activityEvent = ActivityEvent(eventType: .followed, userID: currentUserID, eventID: eventID, date: Date())
                ActivitySystemService.shared.addEventToUserActivity(event: activityEvent, userID: uid)
            }
        }

    }

    func unfollowUser(uid: String, completion: @escaping (Result<FollowStatus, Error>) -> Void) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }
        let databaseKey = "Following/\(currentUserID)/\(uid)"

        databaseRef.child(databaseKey).removeValue { error, _ in
            if let error = error {
                completion(.failure(ServiceError.couldntCompleteTheAction))
            } else {
                self.removeFollower(with: currentUserID, from: uid) { result in
                    switch result {
                    case .success:
                        ActivitySystemService.shared.removeFollowEventForUser(userID: uid)
                        completion(.success(.notFollowing))
                    case .failure(let error):
                        completion(.failure(ServiceError.couldntCompleteTheAction))
                    }

                }
            }
        }
    }

    func insertFollower(with uid: String, to user: String, completion: @escaping (VoidResult) -> Void) {
        let databaseKey = "Followers/\(user)/\(uid)"

        databaseRef.child(databaseKey).setValue(["userID": uid]) { error, _ in
            if let error = error {
                completion(.failure(ServiceError.couldntCompleteTheAction))
            } else {
                completion(.success)
            }
        }
    }

    func removeFollower(with uid: String, from user: String, completion: @escaping (VoidResult) -> Void) {
        let databaseKey = "Followers/\(user)/\(uid)"

        databaseRef.child(databaseKey).removeValue { error, _ in
            if let error = error {
                completion(.failure(ServiceError.couldntCompleteTheAction))
            } else {
                completion(.success)
            }
        }
    }

    func forcefullyRemoveFollower(uid: String, completion: @escaping (VoidResult) -> Void) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }
        let databaseKey = "Following/\(uid)/\(currentUserID)"

        databaseRef.child(databaseKey).removeValue { error, _ in
            if let error = error {
                completion(.failure(ServiceError.couldntCompleteTheAction))
            } else {
                self.removeFollower(with: uid, from: currentUserID) { result in
                    switch result {
                    case .success:
                        completion(.success)
                    case .failure(let error):
                        completion(.failure(error))
                    }

                }
            }
        }
    }

    func undoForcefullRemoval(ofUser uid: String, completion: @escaping (VoidResult) -> Void) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }
        let databaseKey = "Following/\(uid)/\(currentUserID)"

        databaseRef.child(databaseKey).setValue(["userID": currentUserID]) { error, _ in
            if let error = error {
                completion(.failure(ServiceError.couldntCompleteTheAction))
            } else {
                self.insertFollower(with: uid, to: currentUserID) { result in
                    switch result {
                    case .success:
                        completion(.success)
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
}
