//
//  FollowService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.12.2022.
//

import Foundation
import FirebaseDatabase

class FollowSystemService {

    static let shared = FollowSystemService()

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    typealias FollowersNumber = Int

    typealias FollowingNumber = Int

    func getFollowersNumber(for uid: String, completion: @escaping (FollowersNumber) -> Void) {

        let databaseKey =  "Followers/\(uid)"

        databaseRef.child(databaseKey).observeSingleEvent(of: .value) { snapshot in
            completion(Int(snapshot.childrenCount))
        }
    }

    func getFollowingNumber(for uid: String, completion: @escaping (FollowingNumber) -> Void) {

        let databaseKey =  "Following/\(uid)"

        databaseRef.child(databaseKey).observeSingleEvent(of: .value) { snapshot in
            completion(Int(snapshot.childrenCount))
        }
    }

    func getFollowers(for uid: String, completion: @escaping ([ZoogramUser]) -> Void) {

        var followers = [ZoogramUser]()

        let databaseKey = "Followers/\(uid)"

        let dispatchGroup = DispatchGroup()
        databaseRef.child(databaseKey).observeSingleEvent(of: .value) { snapshot in

            for snapshotChild in snapshot.children {

                guard let snapshotChild = snapshotChild as? DataSnapshot,
                      let snapshotDictionary = snapshotChild.value as? [String : String],
                      let userID = snapshotDictionary.first?.value
                else {
                    print("Couldn't convert snapshot to dictionary")
                    return
                }
                dispatchGroup.enter()
                UserService.shared.observeUser(for: userID) { follower in
                    followers.append(follower)
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
                completion(followers)
            }
        }
    }

    func getFollowing(for uid: String, completion: @escaping ([ZoogramUser]) -> Void) {

        var followedUsers = [ZoogramUser]()

        let databaseKey = "Following/\(uid)"

        let dispatchGroup = DispatchGroup()
        databaseRef.child(databaseKey).observeSingleEvent(of: .value) { snapshot in

            for snapshotChild in snapshot.children {

                guard let snapshotChild = snapshotChild as? DataSnapshot,
                      let snapshotDictionary = snapshotChild.value as? [String : String],
                      let userID = snapshotDictionary.first?.value
                else {
                    print("Couldn't convert snapshot to dictionary")
                    return
                }
                dispatchGroup.enter()
                UserService.shared.observeUser(for: userID) { followed in
                    followedUsers.append(followed)
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
                completion(followedUsers)
            }
        }
    }

    func checkFollowStatus(for uid: String, completion: @escaping (FollowStatus) -> Void) {
        let currentUserID = AuthenticationManager.shared.getCurrentUserUID()
        let query = databaseRef.child("Following/\(currentUserID)").queryOrdered(byChild: "userID").queryEqual(toValue: uid)
        query.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                completion(.following)
            } else {
                completion(.notFollowing)
            }
        }
    }

    func followUser(uid: String, completion: @escaping (FollowStatus) -> Void) {
        let currentUserUID = AuthenticationManager.shared.getCurrentUserUID()

        let databaseKey = "Following/\(currentUserUID)/\(uid)"

        databaseRef.child(databaseKey).setValue(["userID": uid]) { error, _ in
            if error == nil {
                self.insertFollower(with: currentUserUID, to: uid) {
                    completion(.following)
                }
                let eventID = ActivitySystemService.shared.createEventUID()
                let activityEvent = ActivityEvent(eventType: .followed, userID: currentUserUID, eventID: eventID, date: Date())
                ActivitySystemService.shared.addEventToUserActivity(event: activityEvent, userID: uid)
            } else {
                print(error)
            }
        }

    }

    func unfollowUser(uid: String, completion: @escaping (FollowStatus) -> Void) {
        let currentUserUID = AuthenticationManager.shared.getCurrentUserUID()

        let databaseKey = "Following/\(currentUserUID)/\(uid)"

        databaseRef.child(databaseKey).removeValue { error, _ in
            if error == nil {
                self.removeFollower(with: currentUserUID, from: uid) {
                    completion(.notFollowing)
                }
            } else {
                print(error)
            }
        }
    }

    func insertFollower(with uid: String, to user: String, completion: @escaping () -> Void) {

        let databaseKey = "Followers/\(user)/\(uid)"

        databaseRef.child(databaseKey).setValue(["userID": uid]) { error, _ in
            if error == nil {
                completion()
            }
        }
    }

    func removeFollower(with uid: String, from user: String, completion: @escaping () -> Void) {

        let databaseKey = "Followers/\(user)/\(uid)"

        databaseRef.child(databaseKey).removeValue { error, _ in
            if error == nil {
                completion()
            }
        }
    }

    func forcefullyRemoveFollower(uid: String, completion: @escaping (IsSuccessful) -> Void) {
        let currentUserUID = AuthenticationManager.shared.getCurrentUserUID()

        let databaseKey = "Following/\(uid)/\(currentUserUID)"

        databaseRef.child(databaseKey).removeValue { error, _ in
            if error == nil {
                self.removeFollower(with: uid, from: currentUserUID) {
                    completion(true)
                }
            }
        }
    }

    func undoForcefullRemoval(ofUser uid: String, completion: @escaping (IsSuccessful) -> Void) {
        let currentUserUID = AuthenticationManager.shared.getCurrentUserUID()

        let databaseKey = "Following/\(uid)/\(currentUserUID)"

        databaseRef.child(databaseKey).setValue(["userID" : currentUserUID]) { error, _ in
            if error == nil {
                self.insertFollower(with: uid, to: currentUserUID) {
                    completion(true)
                }
            }
        }
    }

}
