//
//  UserProfileViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.09.2022.
//

import Foundation

class UserProfileViewModel {
    
    var username: String = ""
    var name: String = ""
    var bio: String = ""
    var profilePhotoURL: String = ""
    var postsCount: Int = 0
    var followersCount: Int = 0
    var followingCount: Int = 0

    
    func getUserData(for id: String = AuthenticationManager.shared.getCurrentUserUID()) {
        DatabaseManager.shared.getUser(for: id) { [weak self] user in
            guard let user = user else {
                return
            }
            self?.username = user.username
            self?.name = user.name ?? ""
            self?.bio = user.bio ?? ""
            self?.profilePhotoURL = user.profilePhotoURL
            self?.postsCount = user.posts
            self?.followersCount = user.followers
            self?.followingCount = user.following
        }
    }
}
