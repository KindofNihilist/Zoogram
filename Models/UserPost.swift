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

public class UserPost: Codable {
    var userID: String
    var postID: String
//    var postType: UserPostType
    var photoURL: String
//    var postURL: URL // either video or full resolution photo url
    var caption: String
    var likeCount: Int
    var commentsCount: Int
    var postedDate: Date
    var likeState: PostLikeState?
    
    var image: UIImage?
    
    lazy var convertedURL: URL = {
        return URL(string: self.photoURL)!
    }()
    
    
    init(userID: String, postID: String, photoURL: String, caption: String, likeCount: Int, commentsCount: Int, postedDate: Date, image: UIImage? = nil) {
        self.userID = userID
        self.postID = postID
        self.photoURL = photoURL
        self.caption = caption
        self.likeCount = likeCount
        self.commentsCount = commentsCount
        self.postedDate = postedDate
        self.image = image
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userID = try container.decode(String.self, forKey: .userID)
        self.postID = try container.decode(String.self, forKey: .postID)
        self.photoURL = try container.decode(String.self, forKey: .photoURL)
        self.caption = try container.decode(String.self, forKey: .caption)
        self.likeCount = try container.decode(Int.self, forKey: .likeCount)
        self.commentsCount = try container.decode(Int.self, forKey: .commentsCount)
        self.postedDate = try container.decode(Date.self, forKey: .postedDate)
    }
    func createDictionary() -> [String: Any]? {
        guard let dictionary = self.dictionary else { return nil }
        return dictionary
    }
    
    func checkIfLikedByCurrentUser(completion: @escaping (PostLikeState) -> Void) {
        DatabaseManager.shared.checkIfPostIsLiked(postID: postID) { likeState in
            completion(likeState)
        }
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
