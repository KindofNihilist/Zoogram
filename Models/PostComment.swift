//
//  PostComment.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 18.05.2023.
//

import Foundation

struct PostComment: Sendable, Codable {
    let commentID: String
    let authorID: String
    let commentText: String
    let datePosted: Date
    let dateTitle: String
    var author: ZoogramUser!
    var canBeEdited: Bool = false
    var shouldBeMarkedUnseen: Bool = false

    init(commentID: String, authorID: String, commentText: String, datePosted: Date, author: ZoogramUser? = nil) {
        self.commentID = commentID
        self.authorID = authorID
        self.commentText = commentText.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        self.datePosted = datePosted
        self.author = author
        self.dateTitle = datePosted.timeAgoDisplay()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let commentText = try container.decode(String.self, forKey: .commentText)
        self.commentID = try container.decode(String.self, forKey: .commentID)
        self.authorID = try container.decode(String.self, forKey: .authorID)
        self.commentText = commentText.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        self.datePosted = try container.decode(Date.self, forKey: .datePosted)
        self.dateTitle = datePosted.timeAgoDisplay()
    }
}
