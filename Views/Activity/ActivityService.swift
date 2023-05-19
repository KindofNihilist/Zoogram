//
//  ActivityService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 19.05.2023.
//

import Foundation

protocol ActivityService: ImageService {
    func observeActivityEvents(completion: @escaping ([ActivityEvent]) -> Void)
    func updateActivityEventsSeenStatus(events: Set<ActivityEvent>, completion: @escaping () -> Void)
    func followSubscriberBack(uid: String, completion: @escaping (FollowStatus) -> Void)
    func unfollowSubscriber(uid: String, completion: @escaping (FollowStatus) -> Void)
}
