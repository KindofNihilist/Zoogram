//
//  Notifications.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 01.02.2024.
//

import Foundation

extension Notification.Name {
    static let didUpdateUserProfile = Notification.Name("didUpdateUserProfile")
    static let shouldListenToAuthenticationState = Notification.Name(rawValue: "ShouldListenToAuthenticationState")
}
