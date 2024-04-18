//
//  Bookmark.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 30.12.2023.
//

import Foundation

class Bookmark: Codable {
    var postID: String
    var postAuthorID: String
    var associatedPost: PostViewModel?

    init(postID: String, postAuthorID: String, associatedPost: PostViewModel? = nil) {
        self.postID = postID
        self.postAuthorID = postAuthorID
        self.associatedPost = associatedPost
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.postID = try container.decode(String.self, forKey: .postID)
        self.postAuthorID = try container.decode(String.self, forKey: .postAuthorID)
    }
    
    enum CodingKeys: CodingKey {
        case postID
        case postAuthorID
    }

    func createDictionary() -> [String: Any]? {
        guard let dictionary = self.dictionary else { return nil }
        return dictionary
    }
}

extension Bookmark: PostViewModelProvider {
    func getPostViewModel() -> PostViewModel? {
        return associatedPost
    }
}
