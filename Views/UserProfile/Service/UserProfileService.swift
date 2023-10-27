//
//  UserProfileService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.04.2023.
//

import Foundation

protocol UserProfileService: PostsService {
    var userID: String { get }
    var dispatchGroup: DispatchGroup { get set }

    func getFollowersCount(completion: @escaping (Int) -> Void)
    func getFollowingCount(completion: @escaping (Int) -> Void)
    func getPostsCount(completion: @escaping (Int) -> Void)
    func getUserData(completion: @escaping (ZoogramUser) -> Void)
    func followUser(completion: @escaping (FollowStatus) -> Void)
    func unfollowUser(completion: @escaping (FollowStatus) -> Void)
}

extension UserProfileService {

    func getUserProfileViewModel(completion: @escaping (UserProfileViewModel) -> Void) {
        var user: ZoogramUser = ZoogramUser()
        var postsCount: Int = 0
        var followersCount: Int = 0
        var followingCount: Int = 0
        
        dispatchGroup.enter()
        getFollowersCount { count in
            followersCount = count
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        getFollowingCount { count in
            followingCount = count
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        getPostsCount { count in
            postsCount = count
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        getUserData { retrievedUser in
            user = retrievedUser
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            completion(UserProfileViewModel(
                user: user,
                postsCount: postsCount,
                followersCount: followersCount,
                followingCount: followingCount))
        }
    }
}
