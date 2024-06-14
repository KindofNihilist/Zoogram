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
        guard userID != event.userID else { return }
        guard let eventDictionary = event.dictionary else { throw ServiceError.unexpectedError }
        let path = "Activity/\(userID)/\(event.eventID)"
        try await databaseRef.child(path).setValue(eventDictionary)
    }

    func updateActivityEventsSeenStatus(events: Set<ActivityEvent>) async throws {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        var updatedEvents = [String: Any]()

        events.forEach { event in
            updatedEvents["Activity/\(currentUserID)/\(event.eventID)/seen"] = true
        }
        try await databaseRef.updateChildValues(updatedEvents)
    }

    func observeActivityEvents() -> AsyncThrowingStream<[ActivityEvent], Error> {
        let currentUserID = UserManager.shared.getUserID()
        let path = "Activity/\(currentUserID)"
        let query = databaseRef.child(path).queryOrderedByKey()
        let dispatchGroup = DispatchGroup()

        return AsyncThrowingStream { continuation in
            query.observe(.value) { snapshot in
                var events = [ActivityEvent]()
                print("observing activities query")
                print("activities: \(snapshot.childrenCount)")
                for snapshotChild in snapshot.children {
                    guard let activityEventSnapshot = snapshotChild as? DataSnapshot,
                          let activityEventDictionary = activityEventSnapshot.value as? [String: Any]
                    else {
                        continuation.finish(throwing: ServiceError.snapshotCastingError)
                        return
                    }
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: activityEventDictionary as Any)
                        var decodedEvent = try JSONDecoder().decode(ActivityEvent.self, from: jsonData)
                        dispatchGroup.enter()
                        UserDataService().getUser(for: decodedEvent.userID) { result in
                            switch result {
                            case .success(let relatedUser):
                                decodedEvent.user = relatedUser
                                events.append(decodedEvent)
                            case .failure(let error):
                                continuation.finish(throwing: error)
                            }
                            dispatchGroup.leave()
                        }
                    } catch {
                        continuation.finish(throwing: ServiceError.jsonParsingError)
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    continuation.yield(events)
                }
            }

        }
    }

    func removeLikeEventForPost(postID: String, postAuthorID: String) async throws {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()

        let path = "Activity/\(postAuthorID)"
        let referenceString = "\(ActivityEventType.postLiked.rawValue)_\(currentUserID)_\(postID)"
        let query = databaseRef.child(path).queryOrdered(byChild: "referenceString").queryEqual(toValue: referenceString)

        do {
            let data = try await query.getData()

            for snapshot in data.children {
                guard let childSnap = snapshot as? DataSnapshot else { throw ServiceError.snapshotCastingError }
                try await childSnap.ref.removeValue()
            }
        }
    }

    func removeCommentEventForPost(commentID: String, postAuthorID: String) async throws {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let path = "Activity/\(postAuthorID)"
        let referenceString = "\(ActivityEventType.postCommented.rawValue)_\(currentUserID)_\(commentID)"
        let query = databaseRef.child(path).queryOrdered(byChild: "referenceString").queryEqual(toValue: referenceString)
        let data = try await query.getData()

        for snapshot in data.children {
            guard let childSnap = snapshot as? DataSnapshot else { throw ServiceError.snapshotCastingError }
            try await childSnap.ref.removeValue()
        }
    }

    func removeFollowEventForUser(userID: String) async throws {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let path = "Activity/\(userID)"
        let referenceString = "\(ActivityEventType.followed.rawValue)_\(currentUserID)"
        let query = databaseRef.child(path).queryOrdered(byChild: "referenceString").queryEqual(toValue: referenceString)
        let data = try await query.getData()

        for snapshot in data.children {
            guard let childSnap = snapshot as? DataSnapshot else { throw ServiceError.snapshotCastingError }
            try await childSnap.ref.removeValue()
        }
    }
}
