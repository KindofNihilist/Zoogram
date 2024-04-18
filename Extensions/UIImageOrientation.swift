//
//  UIImageOrientation.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 14.02.2024.
//

import UIKit.UIImage

extension UIImage.Orientation {
    init( cgOrientation: CGImagePropertyOrientation) {
        switch cgOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}

