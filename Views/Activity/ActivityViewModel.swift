//
//  ActivityViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 26.01.2023.
//

import Foundation

class ActivityViewModel {

    let service: ActivityServiceProtocol

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

    init(service: ActivityServiceProtocol) {
        self.service = service
        observeActivityEvents()
    }

    func observeActivityEvents() {
        service.observeActivityEvents { result in
            switch result {
            case .success(let events):
                self.events = events
                self.hasInitialized.value = true
            case .failure(let error):
                self.hasInitialized.value = false
            }
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
        service.updateActivityEventsSeenStatus(events: seenEvents) { result in
            switch result {
            case .success:
                self.seenEvents = Set<ActivityEvent>()
            case .failure(let error):
                print(error)
            }
        }
    }

    func markEventAsSeen(at indexPath: IndexPath) {
        events[indexPath.row].seen = true
        let seenEvent = events[indexPath.row]
        seenEvents.insert(seenEvent)
    }
}
