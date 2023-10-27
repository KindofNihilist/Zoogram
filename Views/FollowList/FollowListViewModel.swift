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
        FollowSystemService.shared.getFollowers(for: uid) { [weak self] followers in
            self?.users = followers
            completion()
        }
    }

    func getFollowing(completion: @escaping () -> Void) {
        FollowSystemService.shared.getFollowing(for: uid) { followed in
            self.users = followed
            completion()
        }
    }

    func followUser(uid: String, completion: @escaping (FollowStatus) -> Void) {
        FollowSystemService.shared.followUser(uid: uid) { followStatus in
            completion(followStatus)
        }
    }

    func unfollowUser(uid: String, completion: @escaping (FollowStatus) -> Void) {
        FollowSystemService.shared.unfollowUser(uid: uid) { followStatus in
            ActivitySystemService.shared.removeFollowEventForUser(userID: uid)
            completion(followStatus)
        }
    }

    func removeUserFollowingMe(uid: String, completion: @escaping (Bool) -> Void) {
        FollowSystemService.shared.forcefullyRemoveFollower(uid: uid) { result in
            completion(result)
        }
    }

    func undoUserRemoval(uid: String, completion: @escaping (Bool) -> Void) {
        FollowSystemService.shared.undoForcefullRemoval(ofUser: uid) { result in
            completion(result)
        }
    }
}
