//
//  ActivityService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 19.05.2023.
//

import Foundation

protocol ActivityServiceProtocol {
    var activitySystemService: ActivitySystemProtocol { get }
    var followSystemService: FollowSystemProtocol { get }
    var userDataService: UserDataServiceProtocol { get }
    var userPostsService: UserPostsServiceProtocol { get }
    var storageManager: StorageManagerProtocol { get }

    func observeActivityEvents() -> AsyncThrowingStream<[ActivityEvent], Error>
    func updateActivityEventsSeenStatus(events: Set<ActivityEvent>) async throws
    func followSubscriberBack(uid: String) async throws -> FollowStatus
    func unfollowSubscriber(uid: String) async throws -> FollowStatus
    func getAdditionalDataFor(events: [ActivityEvent]) async throws -> [ActivityEvent]
}

class ActivityService: ImageService, ActivityServiceProtocol {
    let activitySystemService: ActivitySystemProtocol
    let followSystemService: FollowSystemProtocol
    let userDataService: UserDataServiceProtocol
    let userPostsService: UserPostsServiceProtocol
    let storageManager: StorageManagerProtocol

    init(activitySystemService: ActivitySystemProtocol,
         followSystemService: FollowSystemProtocol,
         userDataService: UserDataServiceProtocol,
         userPostsService: UserPostsServiceProtocol,
         storageManager: StorageManagerProtocol)
    {
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

    func followSubscriberBack(uid: String) async throws -> FollowStatus {
        return try await followSystemService.followUser(uid: uid)
    }

    func unfollowSubscriber(uid: String) async throws -> FollowStatus {
        return try await followSystemService.unfollowUser(uid: uid)
    }

    func getAdditionalDataFor(events: [ActivityEvent]) async throws -> [ActivityEvent] {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()

        for event in events {
            let user = try await userDataService.getUser(for: event.userID)
            event.user = user

            if let profilePhotoURL = user.profilePhotoURL {
                let profilePhoto = try await getImage(for: profilePhotoURL)
                event.user?.setProfilePhoto(profilePhoto)
            }

            if event.eventType == .postLiked || event.eventType == .postCommented {
                event.post = try await userPostsService.getPost(ofUser: currentUserID, postID: event.postID!)
                event.post?.image = try await getImage(for: event.post?.photoURL)
            }
        }
        return events
    }
}
