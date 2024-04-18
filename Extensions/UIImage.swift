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

    func ratio() -> CGFloat {
        return self.size.width / self.size.height
    }

    func isWidthDominant() -> Bool {
        let ratio = ratio()
        print("width: \(self.size.width)")
        print("height: \(self.size.height)")
        print("width/height = \(ratio)")
        return ratio > 1
    }
}
