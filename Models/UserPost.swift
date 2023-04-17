//
//  UserPost.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.09.2022.
//

import Foundation
import FirebaseDatabase

enum LikeState {
    case liked, notLiked
}

enum BookmarkState {
    case bookmarked, notBookmarked
}

public class UserPost: Codable {
    
    var userID: String
    var postID: String
    var photoURL: String
    var caption: String
    var postedDate: Date
    
    //Used locally 
    var author: ZoogramUser!
    var likesCount: Int!
    var commentsCount: Int!
    var likeState: LikeState = .notLiked
    var bookmarkState: BookmarkState = .notBookmarked
    var image: UIImage?
    
    lazy var convertedURL: URL = {
        return URL(string: self.photoURL)!
    }()
    
    
    init(userID: String, postID: String, photoURL: String, caption: String, likeCount: Int, commentsCount: Int, postedDate: Date, image: UIImage? = nil) {
        self.userID = userID
        self.postID = postID
        self.photoURL = photoURL
        self.caption = caption
        self.likesCount = likeCount
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
        self.postedDate = try container.decode(Date.self, forKey: .postedDate)
    }
    
    func createDictionary() -> [String: Any]? {
        guard let dictionary = self.dictionary else { return nil }
        return dictionary
    }
    
    func checkIfLikedByCurrentUser(completion: @escaping (LikeState) -> Void) {
        LikeSystemService.shared.checkIfPostIsLiked(postID: postID) { likeState in
            completion(likeState)
        }
    }
    
    func isMadeByCurrentUser() -> Bool {
        let currentUserID = AuthenticationManager.shared.getCurrentUserUID()
        return userID == currentUserID
    }
    
    enum CodingKeys: CodingKey {
        case userID
        case postID
        case photoURL
        case caption
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

class PostComment: Codable {
    let commentID: String
    let authorID: String
    let commentText: String
    let datePosted: Date
    var author: ZoogramUser!
    
    init(commentID: String, authorID: String, commentText: String, datePosted: Date) {
        self.commentID = commentID
        self.authorID = authorID
        self.commentText = commentText
        self.datePosted = datePosted
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.commentID = try container.decode(String.self, forKey: .commentID)
        self.authorID = try container.decode(String.self, forKey: .authorID)
        self.commentText = try container.decode(String.self, forKey: .commentText)
        self.datePosted = try container.decode(Date.self, forKey: .datePosted)
    }
}
