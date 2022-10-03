//
//  UserPost.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.09.2022.
//

import Foundation

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
    let owner: ZoogramUser
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
