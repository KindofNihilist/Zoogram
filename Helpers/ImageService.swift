//
//  ImageService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 19.05.2023.
//

import Foundation
import SDWebImage


protocol ImageService {
    func getImage(for urlString: String, completion: @escaping(UIImage) -> Void)
}

extension ImageService {
    func getImage(for urlString: String, completion: @escaping(UIImage) -> Void) {
        let url = URL(string: urlString)
        SDWebImageManager.shared.loadImage(with: url, progress: .none) { downloadedImage, _, _, _, _, _ in
            if let unwrappedImage = downloadedImage {
                completion(unwrappedImage)
            }
        }
    }
}
