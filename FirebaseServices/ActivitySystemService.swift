//
//  ActivitySystem.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 22.02.2023.
//

import Foundation
import FirebaseDatabase

class ActivityService {
    
    static let shared = ActivityService()
    
    private let currentUserID = AuthenticationManager.shared.getCurrentUserUID()
    
    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()
    
    func createEventUID() -> String {
        return databaseRef.child("Activity").childByAutoId().key!
    }
    
    func addEventToUserActivity(event: ActivityEvent, userID: String, completion: @escaping () -> Void = {}) {
        guard let eventDictionary = event.dictionary, userID != event.userID else {
            return
        }
        
        let path = "Activity/\(userID)/\(event.eventID)"
        
        databaseRef.child(path).setValue(eventDictionary) { error, _ in
            guard error == nil else {
                print(error)
                return
            }
            completion()
        }
    }
    
    func updateActivityEventsSeenStatus(events: Set<ActivityEvent>, completion: @escaping () -> Void) {
        var updatedEvents = [String : Any]()
        
        events.forEach { event in
            updatedEvents["Activity/\(currentUserID)/\(event.eventID)/seen"] = true
        }
        
        databaseRef.updateChildValues(updatedEvents) { error, _ in
            if error == nil {
                completion()
                print("Succesfully updated activity events seen status")
            } else {
                print(error)
            }
        }
    }
    
    //For testing purposes
    func updateActivityEventsSeenStatusToFalse(events: [ActivityEvent], completion: () -> Void) {
        var updatedEvents = [String : Any]()
        
        events.forEach { event in
            updatedEvents["Activity/\(currentUserID)/\(event.eventID)/seen"] = false
        }
        
        databaseRef.updateChildValues(updatedEvents) { error, _ in
            if error == nil {
                print("Succesfully updated activity events seen status")
            } else {
                print(error)
            }
        }
    }
    
    func observeActivityEvents(completion: @escaping ([ActivityEvent]) -> Void) {
        
        let path = "Activity/\(currentUserID)"
        
        databaseRef.child(path).queryOrderedByKey().observe(.value) { snapshot in
            var events = [ActivityEvent]()
            
            for snapshotChild in snapshot.children {
                guard let activityEventSnapshot = snapshotChild as? DataSnapshot,
                      let activityEventDictionary = activityEventSnapshot.value as? [String : Any] else {
                    return
                }
                print("Activity event snapshot: ", activityEventSnapshot)
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: activityEventDictionary as Any)
                    let decodedEvent = try JSONDecoder().decode(ActivityEvent.self, from: jsonData)
                    events.append(decodedEvent)
                    print("Decoded event: ", decodedEvent.eventType)
                }
                catch { error
                  print("Couldn't decode activity event data. \(error)")
                }
            }
            completion(events.reversed())
        }
    }
    
    
    func removePostRelatedActivityEvents(postID: String, completion: @escaping () -> Void) {
        let path = "Activity/\(currentUserID)"
        
        let querry = databaseRef.child(path).queryOrdered(byChild: "postID").queryEqual(toValue: postID)
        querry.observeSingleEvent(of: .value) { snapshot in
            
            for snapshotChild in snapshot.children {
                guard let childSnap = snapshotChild as? DataSnapshot else {
                    return
                }
                childSnap.ref.removeValue()
            }
            completion()
        }
    }
    
    func removeLikeEventForPost(postID: String, postAuthorID: String) {
        let path = "Activity/\(postAuthorID)"
        let referenceString = "\(ActivityEventType.postLiked.rawValue)_\(currentUserID)_\(postID)"
        
        let query = databaseRef.child(path).queryOrdered(byChild: "referenceString").queryEqual(toValue: referenceString)
        query.observeSingleEvent(of: .value) { snapshot in
            for snapshotChild in snapshot.children {
                guard let childSnap = snapshotChild as? DataSnapshot else {
                    return
                }
                childSnap.ref.removeValue()
            }
        }
        
        
    }
    
    func removeCommentEventForPost(commentID: String, postAuthorID: String) {
        let path = "Activity/\(postAuthorID)"
        print(path)
        let referenceString = "\(ActivityEventType.postCommented.rawValue)_\(currentUserID)_\(commentID)"
        print("referenceString: ", referenceString)
        let query = databaseRef.child(path).queryOrdered(byChild: "referenceString").queryEqual(toValue: referenceString)
        query.observeSingleEvent(of: .value) { snapshot in
            for snapshotChild in snapshot.children {
                guard let childSnap = snapshotChild as? DataSnapshot else {
                    return
                }
                childSnap.ref.removeValue()
            }
        }
    }
    
    func removeFollowEventForUser(userID: String) {
        let path = "Activity/\(userID)"
        let referenceString = "\(ActivityEventType.followed.rawValue)_\(currentUserID)"
        
        let query = databaseRef.child(path).queryOrdered(byChild: "referenceString").queryEqual(toValue: referenceString)
        query.observeSingleEvent(of: .value) { snapshot in
            for snapshotChild in snapshot.children {
                guard let childSnap = snapshotChild as? DataSnapshot else {
                    return
                }
                childSnap.ref.removeValue()
            }
        }
    }
}
