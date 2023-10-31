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
    var caption: String?
    var postedDate: Date

    // Used locally
    var author: ZoogramUser!
    var likesCount: Int?
    var commentsCount: Int?
    var likeState: LikeState = .notLiked
    var bookmarkState: BookmarkState = .notBookmarked
    var image: UIImage?
    var isNewlyCreated: Bool = false

    lazy var convertedURL: URL = {
        return URL(string: self.photoURL)!
    }()

    init(userID: String, postID: String, photoURL: String, caption: String?, likeCount: Int, commentsCount: Int, postedDate: Date, image: UIImage? = nil, isNewlyCreated: Bool = false) {
        self.userID = userID
        self.postID = postID
        self.photoURL = photoURL
        self.caption = caption?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        self.likesCount = likeCount
        self.commentsCount = commentsCount
        self.postedDate = postedDate
        self.image = image
        self.isNewlyCreated = isNewlyCreated
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caption = try container.decodeIfPresent(String.self, forKey: .caption)
        self.userID = try container.decode(String.self, forKey: .userID)
        self.postID = try container.decode(String.self, forKey: .postID)
        self.photoURL = try container.decode(String.self, forKey: .photoURL)
        self.caption = caption?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        self.postedDate = try container.decode(Date.self, forKey: .postedDate)
    }

    static func createNewPostModel() -> UserPost {
        let userUID = AuthenticationManager.shared.getCurrentUserUID()
        let postUID = UserPostsService.shared.createPostUID()
        return UserPost(userID: userUID,
                        postID: postUID,
                        photoURL: "",
                        caption: nil,
                        likeCount: 0,
                        commentsCount: 0,
                        postedDate: Date(),
                        isNewlyCreated: true)
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


