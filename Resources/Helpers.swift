//
//  Helpers.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.04.2023.
//

import UIKit
import SDWebImage

func sendNotificationToUpdateUserFeed() {
    NotificationCenter.default.post(name: NSNotification.Name("UpdateUserFeed"), object: nil)
}

func sendNotificationToUpdateUserProfile() {
    NotificationCenter.default.post(name: NSNotification.Name("UpdateUserProfile"), object: nil)
}
