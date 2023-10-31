//
//  PostComment.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 18.05.2023.
//

import Foundation

class PostComment: Codable {
    let commentID: String
    let authorID: String
    let commentText: String
    let datePosted: Date
    var author: ZoogramUser!

    init(commentID: String, authorID: String, commentText: String, datePosted: Date) {
        self.commentID = commentID
        self.authorID = authorID
        self.commentText = commentText.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        self.datePosted = datePosted
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let commentText = try container.decode(String.self, forKey: .commentText)
        self.commentID = try container.decode(String.self, forKey: .commentID)
        self.authorID = try container.decode(String.self, forKey: .authorID)
        self.commentText = commentText.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        self.datePosted = try container.decode(Date.self, forKey: .datePosted)
    }

    static func createPostComment(text: String) -> PostComment {
        let commentUID = CommentSystemService.shared.createCommentUID()
        let currentUserID = AuthenticationManager.shared.getCurrentUserUID()
        let formattedText = text.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        let postComent = PostComment(commentID: commentUID,
                                     authorID: currentUserID,
                                     commentText: formattedText,
                                     datePosted: Date())
        return postComent
    }
}
