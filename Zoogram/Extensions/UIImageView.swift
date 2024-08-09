//
//  UIImageView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 19.12.2023.
//

import UIKit.UIImageView
import SDWebImage

extension UIImageView {

    func setImage(with url: URL?, placeholderImage: UIImage) {
        SDWebImageManager.shared.loadImage(with: url, progress: .none) { downloadedImage, _, _, _, _, _ in
            self.image = downloadedImage ?? placeholderImage
        }
    }
}
