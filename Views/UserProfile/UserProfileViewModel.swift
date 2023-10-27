//
//  UserProfileViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.09.2022.
//

import Foundation
import SDWebImage

class UserProfileViewModel {

    var user: ZoogramUser
    var isCurrentUserProfile: Bool = false

    var postsCount: Int?
    var followersCount: Int?
    var followingCount: Int?

    var posts: Observable = Observable([PostViewModel]())

    init(user: ZoogramUser, postsCount: Int, followersCount: Int, followingCount: Int) {
        self.user = user
        self.postsCount = postsCount
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.isCurrentUserProfile = user.isCurrentUserProfile
    }

    init() {
        self.user = ZoogramUser()
        self.postsCount = nil
        self.followersCount = nil
        self.followingCount = nil
        self.isCurrentUserProfile = false
    }

    func insertUserIfPreviouslyObtained(user: ZoogramUser?) {
        guard let obtainedUser = user else {
            return
        }
        self.user = obtainedUser
        self.isCurrentUserProfile = obtainedUser.isCurrentUserProfile
    }

    func updateValuesWithViewModel(_ viewModel: UserProfileViewModel) {
        self.user = viewModel.user
        self.followersCount = viewModel.followersCount
        self.followingCount = viewModel.followingCount
        self.postsCount = viewModel.postsCount
        self.isCurrentUserProfile = viewModel.isCurrentUserProfile
    }
}
