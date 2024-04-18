//
//  NetworkStatusMonitor.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 20.03.2024.
//

import Network

enum ConnectionState {
    case connected
    case disconnected
}

class NetworkStatusMonitor {
    private let monitor = NWPathMonitor()
    private var handlerActionBlock: ((ConnectionState) -> Void)?
    private var latestState: ConnectionState = .connected
    var isBeingHandled: Bool = false

    init(handlerAction: ((ConnectionState) -> Void)?) {
        self.handlerActionBlock = handlerAction
        setupMonitor()
    }

    private func setupMonitor() {
        monitor.pathUpdateHandler = { path in
            if path.status == .unsatisfied {
                self.latestState = .disconnected
                guard self.isBeingHandled == false else { return }
                DispatchQueue.main.async {
                    self.handlerActionBlock?(.disconnected)
                }
            } else if path.status == .satisfied && self.latestState == .disconnected {
                self.latestState = .connected
                DispatchQueue.main.async {
                    self.handlerActionBlock?(.connected)
                }
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }
}
