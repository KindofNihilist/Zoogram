//
//  UserPost.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.09.2022.
//

import Foundation
import FirebaseDatabase

public enum UserPostType: Codable {
    case photo, video
}

public struct UserPost: Codable {
    var userID: String
    var postID: String
//    var postType: UserPostType
    var photoURL: String
//    var postURL: URL // either video or full resolution photo url
    var caption: String
    var likeCount: Int
    var commentsCount: Int
    var postedDate: Date
    
    var image: UIImage?
    
    lazy var convertedURL: URL = {
        return URL(string: self.photoURL)!
    }()
    
    func createDictionary() -> [String: Any]? {
        guard let dictionary = self.dictionary else { return nil }
        return dictionary
    }
    
    enum CodingKeys: CodingKey {
        case userID
        case postID
        case photoURL
        case caption
        case likeCount
        case commentsCount
        case postedDate
    }
    
}

struct PostLike: Codable {
    let userID: String
}

struct CommentLike: Codable {
    let username: String
    let commentIdentifier: String
}

struct PostComment: Codable {
    let identifier: String
    let commentAuthorUsername: String
    let text: String
    let createdDate: Date
}
