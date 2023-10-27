//
//  ActivityViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 26.01.2023.
//

import Foundation

class ActivityViewModel {

    let service: ActivityService

    private var events = [ActivityEvent]() {
        didSet {
            checkIfHasUnseenEvents()
        }
    }
    private var seenEvents = Set<ActivityEvent>()

    var eventsCount: Int {
        return events.count
    }

    var hasInitialized = Observable(false)
    var hasUnseenEvents = Observable(false)
    var hasZeroEvents: Bool {
        return events.isEmpty
    }

    init(service: ActivityService) {
        self.service = service
        fetchActivityDataOnInit()
    }

    private func fetchActivityDataOnInit() {
        service.observeActivityEvents { events in
            self.events = events
            self.hasInitialized.value = true
        }
    }

    func checkIfHasUnseenEvents() {
        if events.filter({$0.seen == false}).count != 0 {
            hasUnseenEvents.value = true
        } else {
            hasUnseenEvents.value = false
        }
    }

    func getEvent(for indexPath: IndexPath) -> ActivityEvent {
        return events[indexPath.row]
    }

    func eventSeenStatus(at indexPath: IndexPath) -> Bool {
        return events[indexPath.row].seen
    }

    func updateActivityEventsSeenStatus() {
        service.updateActivityEventsSeenStatus(events: seenEvents) {
            self.seenEvents = Set<ActivityEvent>()
        }
    }

    func markEventAsSeen(at indexPath: IndexPath) {
        events[indexPath.row].seen = true
        let seenEvent = events[indexPath.row]
        seenEvents.insert(seenEvent)
    }
}
