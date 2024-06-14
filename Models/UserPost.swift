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

public struct UserPost: Sendable, Codable {

    var userID: String
    var postID: String
    var photoURL: String
    var caption: String?
    var postedDate: Date

    // Used locally, are not uploaded to the database as part of UserPost model, retrieved separetely.
    var author: ZoogramUser!
    var likesCount: Int = 0
    var commentsCount: Int = 0
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caption = try container.decodeIfPresent(String.self, forKey: .caption)
        self.userID = try container.decode(String.self, forKey: .userID)
        self.postID = try container.decode(String.self, forKey: .postID)
        self.photoURL = try container.decode(String.self, forKey: .photoURL)
        self.caption = caption?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        self.postedDate = try container.decode(Date.self, forKey: .postedDate)
    }

    enum CodingKeys: CodingKey {
        case userID
        case postID
        case photoURL
        case caption
        case postedDate
    }

    mutating func switchLikeState() {
        if likeState == .liked {
            likeState = .notLiked
            likesCount -= 1
        } else if likeState == .notLiked {
            likeState = .liked
            likesCount += 1
        }
    }

    mutating func switchBookmarkState() {
        if bookmarkState == .bookmarked {
            bookmarkState = .notBookmarked
        } else if bookmarkState == .notBookmarked {
            bookmarkState = .bookmarked
        }
    }

    mutating func changeIsNewlyCreatedStatus(to value: Bool) {
        isNewlyCreated = value
    }

    func createDictionary() -> [String: Any]? {
        guard let dictionary = self.dictionary else { return nil }
        return dictionary
    }

    func isMadeByCurrentUser() -> Bool {
        let currentUserID = UserManager.shared.getUserID()
        return userID == currentUserID
    }

    static func createNewPostModel() -> UserPost {
        let userUID = UserManager.shared.getUserID()
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
}

extension UserPost: PostViewModelProvider {
    func getPostViewModel() -> PostViewModel? {
        return PostViewModel(post: self)
    }
}
