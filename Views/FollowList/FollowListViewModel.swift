//
//  FollowListViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 02.11.2022.
//

import Foundation

class FollowListViewModel {
    
    var uid: String!
    
    var users = [ZoogramUser]()
    
    func getFollowers(completion: @escaping () -> Void) {
        DatabaseManager.shared.getFollowers(for: uid) { [weak self] followers in
            let dispatchGroup = DispatchGroup()
            
            self?.users = followers
            
            for user in self!.users {
                dispatchGroup.enter()
                user.checkIfFollowedByCurrentUser {
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion()
            }
        }
    }
    
    func getFollowing(completion: @escaping () -> Void) {
        DatabaseManager.shared.getFollowing(for: uid) { followed in
            let dispatchGroup = DispatchGroup()
            
            self.users = followed
            
            
            for user in self.users {
                dispatchGroup.enter()
                user.checkIfFollowedByCurrentUser {
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion()
            }
        }
    }
    
    func followUser(uid: String, completion: @escaping (Bool) -> Void) {
        DatabaseManager.shared.followUser(uid: uid) { success in
            completion(success)
        }
    }
    
    func unfollowUser(uid: String, completion: @escaping (Bool) -> Void) {
        DatabaseManager.shared.unfollowUser(uid: uid) { success in
            completion(success)
        }
    }
    
    func removeUserFollowingMe(uid: String, completion: @escaping (Bool) -> Void) {
        DatabaseManager.shared.forcefullyRemoveFollower(uid: uid) { result in
            completion(result)
        }
    }
    
    func undoUserRemoval(uid: String, completion: @escaping (Bool) -> Void) {
        DatabaseManager.shared.undoForcefullRemoval(ofUser: uid) { result in
            completion(result)
        }
    }
    
}
