//
//  Models.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 20.01.2022.
//

import Foundation

enum Gender: String {
    case male = "Male"
    case female = "Female"
    case other = "Other"
}

enum FollowCellType {
    case following, followers
}

enum PostLikeState {
    case liked, notLiked
}

public enum FollowStatus {
    case following // Indicates the current user is following the other user
    case notFollowing // Indicates the current user is not following the other user
}
