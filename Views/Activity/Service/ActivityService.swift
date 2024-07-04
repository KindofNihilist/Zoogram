//
//  ActivityService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 19.05.2023.
//

import Foundation

protocol ActivityServiceProtocol: Sendable {
    var activitySystemService: ActivitySystemProtocol { get }
    var followSystemService: FollowSystemProtocol { get }
    var userDataService: UserDataServiceProtocol { get }
    var userPostsService: UserPostsServiceProtocol { get }
    var storageManager: StorageManagerProtocol { get }

    func observeActivityEvents() -> AsyncThrowingStream<[ActivityEvent], Error>
    func updateActivityEventsSeenStatus(events: Set<ActivityEvent>) async throws
    func followSubscriberBack(uid: String) async throws
    func unfollowSubscriber(uid: String) async throws
    func getAdditionalDataFor(events: [ActivityEvent]) async throws -> [ActivityEvent]
}

final class ActivityService: ActivityServiceProtocol {

    let activitySystemService: ActivitySystemProtocol
    let followSystemService: FollowSystemProtocol
    let userDataService: UserDataServiceProtocol
    let userPostsService: UserPostsServiceProtocol
    let storageManager: StorageManagerProtocol

    init(activitySystemService: ActivitySystemProtocol,
         followSystemService: FollowSystemProtocol,
         userDataService: UserDataServiceProtocol,
         userPostsService: UserPostsServiceProtocol,
         storageManager: StorageManagerProtocol) {
        self.activitySystemService = activitySystemService
        self.followSystemService = followSystemService
        self.userDataService = userDataService
        self.userPostsService = userPostsService
        self.storageManager = storageManager
    }

    func observeActivityEvents() -> AsyncThrowingStream<[ActivityEvent], Error> {
        return activitySystemService.observeActivityEvents()
    }

    func updateActivityEventsSeenStatus(events: Set<ActivityEvent>) async throws {
        try await activitySystemService.updateActivityEventsSeenStatus(events: events)
    }

    func followSubscriberBack(uid: String) async throws {
        try await followSystemService.followUser(uid: uid)
    }

    func unfollowSubscriber(uid: String) async throws {
        try await followSystemService.unfollowUser(uid: uid)
    }

    func getAdditionalDataFor(events: [ActivityEvent]) async throws -> [ActivityEvent] {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()

        let eventsWithData = try await withThrowingTaskGroup(of: (Int, ActivityEvent).self, returning: [ActivityEvent].self) { group in

            for (index, event) in events.enumerated() {
                group.addTask {
                    var eventWithData = event
                    let user = try await self.userDataService.getUser(for: eventWithData.userID)
                    eventWithData.user = user

                    if let profilePhotoURL = user.profilePhotoURL {
                        let profilePhoto = try await ImageService.shared.getImage(for: profilePhotoURL)
                        eventWithData.user?.setProfilePhoto(profilePhoto)
                    }

                    if eventWithData.eventType == .postLiked || eventWithData.eventType == .postCommented {
                        var associatedPost = try await self.userPostsService.getPost(ofUser: currentUserID, postID: eventWithData.postID!)
                        associatedPost.image = try await ImageService.shared.getImage(for: associatedPost.photoURL)
                        eventWithData.post = associatedPost
                    }
                    return (index, eventWithData)
                }
            }

            var eventsWithAdditionalData = events
            for try await (index, event) in group {
                eventsWithAdditionalData[index] = event
            }
            return eventsWithAdditionalData
        }
        return eventsWithData
    }
}
