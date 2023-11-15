//
//  UIImage.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 01.11.2023.
//

import UIKit.UIImage

extension UIImage {
    func croppedInRect(rect: CGRect) -> UIImage {
        func rad(_ degree: Double) -> CGFloat {
            return CGFloat(degree / 180.0 * .pi)
        }

        var rectTransform: CGAffineTransform
        switch imageOrientation {
        case .left:
            rectTransform = CGAffineTransform(rotationAngle: rad(90)).translatedBy(x: 0, y: -self.size.height)
        case .right:
            rectTransform = CGAffineTransform(rotationAngle: rad(-90)).translatedBy(x: -self.size.width, y: 0)
        case .down:
            rectTransform = CGAffineTransform(rotationAngle: rad(-180)).translatedBy(x: -self.size.width, y: -self.size.height)
        default:
            rectTransform = .identity
        }
        rectTransform = rectTransform.scaledBy(x: self.scale, y: self.scale)

        let imageRef = self.cgImage!.cropping(to: rect.applying(rectTransform))
        let result = UIImage(cgImage: imageRef!, scale: self.scale, orientation: self.imageOrientation)
        return result
    }

    func compressed() -> UIImage? {
        let originalImageSize = NSData(data: self.jpegData(compressionQuality: 1)!).count
        print("Original image size in KB: %f", Double(originalImageSize).rounded())
        let jpegData = self.jpegData(compressionQuality: 1)
        print("Compressed image size in KB: %f", Double(jpegData!.count).rounded())
        let compressedImage = UIImage(data: jpegData!)
        return compressedImage
    }

    func ratio() -> CGFloat {
        return self.size.width / self.size.height
    }

    func isWidthDominant() -> Bool {
        return self.size.width / self.size.height > 1
    }
}
