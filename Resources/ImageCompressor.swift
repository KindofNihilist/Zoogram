//
//  ImageCompressor.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 18.10.2022.
//

import UIKit

typealias CompressedImage = UIImage

struct ImageCompressor {

    static func compress(image: UIImage, completion: @escaping (CompressedImage) -> Void) {
        let actualHeight = image.size.height
        let actualWidth = image.size.width
        let imgRatio = actualWidth/actualHeight
        let maxWidth: CGFloat = 1280.0
        let resizedHeight: CGFloat = (maxWidth/imgRatio).rounded(.down)
        let compressionQuality: CGFloat = 0.6

        let rect = CGRect(x: 0, y: 0, width: maxWidth, height: resizedHeight)
        UIGraphicsBeginImageContext(rect.size)
        image.draw(in: rect)
        let img: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        let imageData: Data? = img.jpegData(compressionQuality: compressionQuality)
        UIGraphicsEndImageContext()
        if let data = imageData,
           let compressedImage = UIImage(data: data) {
            completion(compressedImage)
        }
    }
}
