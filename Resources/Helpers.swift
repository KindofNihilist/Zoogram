//
//  Helpers.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.04.2023.
//

import UIKit
import SDWebImage

func getImageForURL(_ url: URL) -> UIImage? {
    var image: UIImage?
    
    SDWebImageManager.shared.loadImage(with: url, progress: .none) { retrievedImage, _, _, _, _, _ in
        image = retrievedImage
    }
    return image
}

func currentUserID() -> String {
    AuthenticationManager.shared.getCurrentUserUID()
}
