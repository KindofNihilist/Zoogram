//
//  ActivitySystemMock.swift
//  ZoogramTests
//
//  Created by Artem Dolbiiev on 10.07.2024.
//

import Foundation
@testable import Zoogram

final class ActivitySystemMock: ActivitySystemProtocol {
    func createEventUID() -> String {
        return ""
    }
    
    func addEventToUserActivity(event: Zoogram.ActivityEvent, userID: String) async throws {
        return
    }
    
    func updateActivityEventsSeenStatus(events: Set<Zoogram.ActivityEvent>) async throws {
        return
    }
    
    func observeActivityEvents() -> AsyncThrowingStream<[Zoogram.ActivityEvent], any Error> {
        return AsyncThrowingStream { continuation in
            continuation.yield([])
        }
    }
    
    func removeLikeEventForPost(postID: String, postAuthorID: String) async throws {
        return
    }
    
    func removeCommentEventForPost(commentID: String, postAuthorID: String) async throws {
        return
    }
    
    func removeFollowEventForUser(userID: String) async throws {
        return
    }
    

}
