//
//  ActivitySystemService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 22.02.2023.
//

import Foundation
@preconcurrency import FirebaseDatabase

protocol ActivitySystemProtocol: Sendable {
    func createEventUID() -> String
    func addEventToUserActivity(event: ActivityEvent, userID: String) async throws
    func updateActivityEventsSeenStatus(events: Set<ActivityEvent>) async throws
    func observeActivityEvents() -> AsyncThrowingStream<[ActivityEvent], Error>
    func removeLikeEventForPost(postID: String, postAuthorID: String) async throws
    func removeCommentEventForPost(commentID: String, postAuthorID: String) async throws
    func removeFollowEventForUser(userID: String) async throws
}

final class ActivitySystemService: ActivitySystemProtocol {

    static let shared = ActivitySystemService()

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    func createEventUID() -> String {
        return databaseRef.child("Activity").childByAutoId().key!
    }

    func addEventToUserActivity(event: ActivityEvent, userID: String) async throws {
        let eventType = event.eventType.rawValue
        var referenceString = ActivityEvent.generateReferenceString(for: event)
        guard userID != event.userID else { return }
        guard let eventDictionary = event.dictionary else { throw ServiceError.unexpectedError }
        let path = "Activity/\(userID)/\(referenceString)"
        try await databaseRef.child(path).setValue(eventDictionary)
    }

    func updateActivityEventsSeenStatus(events: Set<ActivityEvent>) async throws {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        var updatedEvents = [String: Any]()
        events.forEach { event in
            let referenceString = ActivityEvent.generateReferenceString(for: event)
            updatedEvents["Activity/\(currentUserID)/\(referenceString)/seen"] = true
        }
        try await databaseRef.updateChildValues(updatedEvents)
    }

    func observeActivityEvents() -> AsyncThrowingStream<[ActivityEvent], Error> {
        let currentUserID = UserManager.shared.getUserID()
        let path = "Activity/\(currentUserID)"
        let query = databaseRef.child(path).queryOrdered(byChild: "timestamp")

        return AsyncThrowingStream { continuation in
            query.observe(.value) { snapshot in
                var events = [ActivityEvent]()
                for snapshotChild in snapshot.children {
                    guard let activityEventSnapshot = snapshotChild as? DataSnapshot,
                          let activityEventDictionary = activityEventSnapshot.value as? [String: Any]
                    else {
                        continuation.finish(throwing: ServiceError.snapshotCastingError)
                        return
                    }
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: activityEventDictionary as Any)
                        let decodedEvent = try JSONDecoder().decode(ActivityEvent.self, from: jsonData)
                        events.append(decodedEvent)
                    } catch {
                        continuation.finish(throwing: ServiceError.jsonParsingError)
                    }
                }
                continuation.yield(events)
            }
        }
    }

    func removeLikeEventForPost(postID: String, postAuthorID: String) async throws {
        let path = "Activity/\(postAuthorID)"
        let referenceString = ActivityEvent.generateReferenceStringForPost(postID)
        let query = databaseRef.child(path).child(referenceString)
        try await query.setValue(nil)
    }

    func removeCommentEventForPost(commentID: String, postAuthorID: String) async throws {
        let path = "Activity/\(postAuthorID)"
        let referenceString = ActivityEvent.generateReferenceStringForComment(commentID)
        let query = databaseRef.child(path).child(referenceString)
        try await query.setValue(nil)
    }

    func removeFollowEventForUser(userID: String) async throws {
        let path = "Activity/\(userID)"
        let referenceString = ActivityEvent.generateReferenceStringForFollowEvent()
        let query = databaseRef.child(path).child(referenceString)
        try await query.setValue(nil)
    }
}
