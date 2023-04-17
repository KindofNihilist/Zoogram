//
//  UserProfileViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.09.2022.
//

import Foundation
import SDWebImage

class UserProfileViewModel {
    
    let user: ZoogramUser
    var isCurrentUserProfile: Bool = false

    var postsCount: Int
    var followersCount: Int
    var followingCount: Int
    
    var posts: [PostViewModel] = [PostViewModel]()
    
    init(user: ZoogramUser, postsCount: Int, followersCount: Int, followingCount: Int, isCurrentUserProfile: Bool) {
        self.user = user
        self.postsCount = postsCount
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.isCurrentUserProfile = isCurrentUserProfile
    }
    
    init() {
        self.user = ZoogramUser()
        self.postsCount = 0
        self.followersCount = 0
        self.followingCount = 0
        self.isCurrentUserProfile = false
    }
}
