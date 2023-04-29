//
//  ActivityViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 26.01.2023.
//

import Foundation

class ActivityViewModel {
    
    var events = [ActivityEvent]()
    var seenEvents = Set<ActivityEvent>()
    
    func getAdditionalDataForEvents(events: [ActivityEvent], completion: @escaping () -> Void) {
        let currentUserID = AuthenticationManager.shared.getCurrentUserUID()
        let dispatchGroup = DispatchGroup()
        print("inside get event data method")
        for event in events {
            print(event.eventType.rawValue)
            switch event.eventType {
                
            case .postLiked:
                dispatchGroup.enter()
                UserService.shared.getUser(for: event.userID) { user in
                    event.user = user
                    dispatchGroup.leave()
                }
                
                dispatchGroup.enter()
                UserPostsService.shared.getPost(ofUser: currentUserID, postID: event.postID!) { post in
                    event.post = post
                    dispatchGroup.leave()
                }
            
            case .postCommented:
                dispatchGroup.enter()
                UserService.shared.getUser(for: event.userID) { user in
                    event.user = user
                    dispatchGroup.leave()
                }
                
                dispatchGroup.enter()
                UserPostsService.shared.getPost(ofUser: currentUserID, postID: event.postID!) { post in
                    event.post = post
                    dispatchGroup.leave()
                }
                
            case .followed:
                dispatchGroup.enter()
                UserService.shared.getUser(for: event.userID) { user in
                    event.user = user
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.events = events
            print("dispatch group is not notified")
            print("events with data", self.events)
            completion()
        }
    }
}
