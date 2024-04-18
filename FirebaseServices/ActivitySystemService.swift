//
//  ActivitySystemService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 22.02.2023.
//

import Foundation
import FirebaseDatabase

protocol ActivitySystemProtocol {
    func createEventUID() -> String
    func addEventToUserActivity(event: ActivityEvent, userID: String, completion: @escaping (VoidResult) -> Void)
    func updateActivityEventsSeenStatus(events: Set<ActivityEvent>, completion: @escaping (VoidResult) -> Void)
    func observeActivityEvents(completion: @escaping (Result<[ActivityEvent], Error>) -> Void)
    func removePostRelatedActivityEvents(postID: String, completion: @escaping (VoidResult) -> Void)
    func removeLikeEventForPost(postID: String, postAuthorID: String)
    func removeCommentEventForPost(commentID: String, postAuthorID: String)
    func removeFollowEventForUser(userID: String)
}

class ActivitySystemService: ActivitySystemProtocol {

    static let shared = ActivitySystemService()

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    func createEventUID() -> String {
        return databaseRef.child("Activity").childByAutoId().key!
    }

    func addEventToUserActivity(event: ActivityEvent, userID: String, completion: @escaping (VoidResult) -> Void = {_ in}) {
        guard let eventDictionary = event.dictionary, userID != event.userID else {
            return
        }

        let path = "Activity/\(userID)/\(event.eventID)"
        databaseRef.child(path).setValue(eventDictionary) { error, _ in
            if let error = error {
                completion(.failure(ServiceError.couldntUploadData))
            } else {
                completion(.success)
            }
        }
    }

    func updateActivityEventsSeenStatus(events: Set<ActivityEvent>, completion: @escaping (VoidResult) -> Void) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }
        var updatedEvents = [String: Any]()

        events.forEach { event in
            updatedEvents["Activity/\(currentUserID)/\(event.eventID)/seen"] = true
        }

        databaseRef.updateChildValues(updatedEvents) { error, _ in
            if let error = error {
                completion(.failure(ServiceError.couldntUploadData))
            } else  {
                completion(.success)
            }
        }
    }

    func observeActivityEvents(completion: @escaping (Result<[ActivityEvent], Error>) -> Void) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }
        let path = "Activity/\(currentUserID)"

        databaseRef.child(path).queryOrderedByKey().observe(.value) { snapshot in
            var events = [ActivityEvent]()

            for snapshotChild in snapshot.children {
                guard let activityEventSnapshot = snapshotChild as? DataSnapshot,
                      let activityEventDictionary = activityEventSnapshot.value as? [String: Any] 
                else {
                    completion(.failure(ServiceError.snapshotCastingError))
                    return
                }
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: activityEventDictionary as Any)
                    let decodedEvent = try JSONDecoder().decode(ActivityEvent.self, from: jsonData)
                    events.append(decodedEvent)
                } catch {
                    completion(.failure(ServiceError.jsonParsingError))
                }
            }
            completion(.success(events.reversed()))
        } withCancel: { error in
            completion(.failure(error))
        }
    }

    func removePostRelatedActivityEvents(postID: String, completion: @escaping (VoidResult) -> Void) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }

        let path = "Activity/\(currentUserID)"
        let querry = databaseRef.child(path).queryOrdered(byChild: "postID").queryEqual(toValue: postID)

        querry.getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntDeleteData))
                return
            } else if let snapshot = snapshot {
                for snapshotChild in snapshot.children {
                    guard let childSnap = snapshotChild as? DataSnapshot
                    else {
                        completion(.failure(ServiceError.snapshotCastingError))
                        return
                    }
                    childSnap.ref.removeValue() { error, _ in
                        if let error = error {
                            completion(.failure(ServiceError.couldntDeleteData))
                            return
                        }
                    }
                }
                completion(.success)
            }
        }
    }

    func removeLikeEventForPost(postID: String, postAuthorID: String) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }

        let path = "Activity/\(postAuthorID)"
        let referenceString = "\(ActivityEventType.postLiked.rawValue)_\(currentUserID)_\(postID)"
        let query = databaseRef.child(path).queryOrdered(byChild: "referenceString").queryEqual(toValue: referenceString)

        query.getData { error, snapshot in
            if let snapshot = snapshot {
                for snapshotChild in snapshot.children {
                    guard let childSnap = snapshotChild as? DataSnapshot else {
                        return
                    }
                    childSnap.ref.removeValue()
                }
            }
        }
    }

    func removeCommentEventForPost(commentID: String, postAuthorID: String) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }

        let path = "Activity/\(postAuthorID)"
        let referenceString = "\(ActivityEventType.postCommented.rawValue)_\(currentUserID)_\(commentID)"
        let query = databaseRef.child(path).queryOrdered(byChild: "referenceString").queryEqual(toValue: referenceString)

        query.getData { error, snapshot in
            if let snapshot = snapshot {
                for snapshotChild in snapshot.children {
                    guard let childSnap = snapshotChild as? DataSnapshot else {
                        return
                    }
                    childSnap.ref.removeValue()
                }
            }
        }
    }

    func removeFollowEventForUser(userID: String) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }

        let path = "Activity/\(userID)"
        let referenceString = "\(ActivityEventType.followed.rawValue)_\(currentUserID)"
        let query = databaseRef.child(path).queryOrdered(byChild: "referenceString").queryEqual(toValue: referenceString)

        query.getData { error, snapshot in
            if let snapshot = snapshot {
                for snapshotChild in snapshot.children {
                    guard let childSnap = snapshotChild as? DataSnapshot else {
                        return
                    }
                    childSnap.ref.removeValue()
                }
            }
        }
    }
}
