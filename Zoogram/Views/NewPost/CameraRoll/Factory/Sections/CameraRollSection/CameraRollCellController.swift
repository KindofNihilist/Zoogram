//
//  CameraRollCellController.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 16.11.2023.
//

import Photos.PHAsset
import UIKit.UIImage

class CameraRollCellController: GenericCellController<PhotoCollectionViewCell> {

    var photo: PHAsset

    var requestedImage: UIImage?

    var action: ((IndexPath) -> Void)?

    init(photo: PHAsset, action: @escaping (IndexPath) -> Void) {
        self.photo = photo
        self.action = action
    }

    override func configureCell(_ cell: PhotoCollectionViewCell, at indexPath: IndexPath? = nil) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isSynchronous = true
        if let requestedImage = self.requestedImage {
            cell.configure(with: requestedImage)
        } else {
            PHCachingImageManager.default().requestImage(
                for: photo,
                targetSize: cell.frame.size,
                contentMode: .aspectFill,
                options: options) { image, _ in
                    guard let image = image else {
                        return
                    }
                    self.requestedImage = image
                    cell.configure(with: image)
                }
        }
    }

    override func didSelectCell(at indexPath: IndexPath) {
        action?(indexPath)
    }
}
