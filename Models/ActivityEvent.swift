//
//  ActivityEvent.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 22.02.2023.
//

import Foundation

enum ActivityEventType: String, Codable {
    case postLiked
    case followed
    case postCommented
}

struct ActivityEvent: Sendable, Codable, Hashable {

    let eventType: ActivityEventType
    let userID: String
    let postID: String?
    let eventID: String
    let date: Date
    let text: String?
    let commentID: String?
    let referenceString: String?
    var seen: Bool

    // Used locally
    var user: ZoogramUser?
    var post: UserPost?

    init(eventType: ActivityEventType, userID: String, postID: String? = nil, eventID: String, date: Date, text: String? = nil, seen: Bool = false, commentID: String? = nil) {
        self.eventType = eventType
        self.userID = userID
        self.postID = postID
        self.eventID = eventID
        self.date = date
        self.text = text
        self.commentID = commentID
        self.seen = seen
        switch eventType {
        case .postLiked:
            self.referenceString = "\(eventType.rawValue)_\(userID)_\(postID!)"
        case .postCommented:
            self.referenceString = "\(eventType.rawValue)_\(userID)_\(commentID!)"
        case .followed:
            self.referenceString = "\(eventType.rawValue)_\(userID)"
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.eventType = try container.decode(ActivityEventType.self, forKey: .eventType)
        self.userID = try container.decode(String.self, forKey: .userID)
        self.postID = try container.decodeIfPresent(String.self, forKey: .postID)
        self.eventID = try container.decode(String.self, forKey: .eventID)
        self.date = try container.decode(Date.self, forKey: .date)
        self.text = try container.decodeIfPresent(String.self, forKey: .text)
        self.commentID = try container.decodeIfPresent(String.self, forKey: .commentID)
        self.seen = try container.decode(Bool.self, forKey: .seen)
        self.referenceString = nil
    }

    static func createActivityEventFor(comment: PostComment, postID: String) -> ActivityEvent {
        let eventID = ActivitySystemService.shared.createEventUID()

        return ActivityEvent(eventType: .postCommented,
                      userID: comment.authorID,
                      postID: postID,
                      eventID: eventID,
                      date: Date(),
                      text: comment.commentText,
                      commentID: comment.commentID
        )
    }

    static func createActivityEventFor(likedPostID: String) -> ActivityEvent {
        let currentUserID = UserManager.shared.getUserID()
        let eventID = ActivitySystemService.shared.createEventUID()
        return ActivityEvent(
            eventType: .postLiked,
            userID: currentUserID,
            postID: likedPostID,
            eventID: eventID,
            date: Date())
    }

    static func == (lhs: ActivityEvent, rhs: ActivityEvent) -> Bool {
        return lhs.eventID == rhs.eventID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(eventID)
    }

    enum CodingKeys: CodingKey {
        case eventType
        case userID
        case postID
        case eventID
        case date
        case text
        case commentID
        case seen
        case referenceString
    }
}
