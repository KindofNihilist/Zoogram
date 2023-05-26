//
//  Helpers.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.04.2023.
//

import UIKit
import SDWebImage

//func getImageForURL(_ url: URL, completion: @escaping (UIImage?) -> Void) {
//    SDWebImageManager.shared.loadImage(with: url, progress: .none) { retrievedImage, _, _, _, _, _ in
//        completion(retrievedImage)
//    }
//}

func currentUserID() -> String {
    AuthenticationManager.shared.getCurrentUserUID()
}


func sendNotificationToUpdateUserFeed() {
    NotificationCenter.default.post(name: NSNotification.Name("UpdateUserFeed"), object: nil)
}

func sendNotificationToUpdateUserProfile() {
    NotificationCenter.default.post(name: NSNotification.Name("UpdateUserProfile"), object: nil)
}
