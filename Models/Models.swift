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

enum CellType {
    case following, followers
}

public struct User: Codable {
    let profilePhotoURL: String
    let emailAdress: String
    let phoneNumber: String?
    let username: String
    let name: String?
    let bio: String?
    let birthday: String?
    let gender: String?
    let following: Int
    let followers: Int
    let posts: Int
    let joinDate: Double //TimeInterval
}

struct UserCount {
    let followers: Int
    let following: Int
    let posts: Int
}

public enum UserPostType {
    case photo, video
}

public struct UserPost {
    let identifier: String
    let postType: UserPostType
    let thumbnailImage: URL
    let postURL: URL // either video or full resolution photo url
    let caption: String?
    let likeCount: [PostLikes]
    let comments: [PostComment]
    let postedDate: Date
    let taggedUsers: [String]
    let owner: User
}

struct PostLikes {
    let username: String
    let postID: String
}

struct CommentLike {
    let username: String
    let commentIdentifier: String
}

struct PostComment {
    let identifier: String
    let commentAuthorUsername: String
    let text: String
    let createdDate: Date
    let likes: [CommentLike]
}
