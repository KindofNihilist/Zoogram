//
//  NetworkStatusMonitor.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 20.03.2024.
//

import Network

enum ConnectionState: Sendable {
    case connected
    case disconnected
}

actor NetworkStatusMonitor {
    private let monitor = NWPathMonitor()
    private var handlerActionBlock: ((ConnectionState) -> Void)?
    private var latestState: ConnectionState = .connected
    var isBeingHandled: Bool = false

    func setupMonitor() {
        monitor.pathUpdateHandler = { path in
            Task {
                let latestConnectionState = await self.getLatestConnectionState()
                if path.status == .unsatisfied {
                    await self.setLatestState(to: .disconnected)
                    guard await self.isBeingHandled == false else { return }
                    await self.callHandler(with: .disconnected)
                } else if path.status == .satisfied && latestConnectionState == .disconnected {
                    await self.setLatestState(to: .connected)
                    await self.callHandler(with: .connected)
                }
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }

    private func setLatestState(to state: ConnectionState) {
        self.latestState = state
    }

    private func getLatestConnectionState() -> ConnectionState {
        return self.latestState
    }

    private func callHandler(with state: ConnectionState) {
        self.handlerActionBlock?(state)
    }

    func setHandler(_ handler: @Sendable @escaping (ConnectionState) -> Void) {
        self.handlerActionBlock = handler
    }

    func setConnectionHandlerState(isBeingHandled: Bool) {
        self.isBeingHandled = isBeingHandled
    }
}
