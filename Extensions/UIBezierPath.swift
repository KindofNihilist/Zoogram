//
//  UIBezierPath.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 06.02.2024.
//

import UIKit.UIBezierPath

extension UIBezierPath {

    func scaledToFit(rect: CGRect) -> UIBezierPath {
        let pathBounds = self.cgPath.boundingBox
        let center = CGPoint(x: pathBounds.midX, y: pathBounds.midY)

        let scaledWidth = rect.width / pathBounds.width
        let scaledHeight = rect.height / pathBounds.height
        let factor = min(scaledWidth, max(scaledHeight, 0.0))

        var transform = CGAffineTransform.identity
        transform = transform.concatenating(CGAffineTransform(translationX: -center.x, y: -center.y))
        transform = transform.concatenating(CGAffineTransform(scaleX: factor, y: factor))
        transform = transform.concatenating(CGAffineTransform(translationX: center.x, y: center.y))
        self.apply(transform)
        return self
    }

    func scaled(to rect: CGRect) -> UIBezierPath {
        let pathBounds = self.cgPath.boundingBox
        let widthDifferenceCoefficient = (pathBounds.width / rect.width)
        let heightDifferenceCoefficient = (pathBounds.height / rect.height)
        let factor = (min(widthDifferenceCoefficient, max(heightDifferenceCoefficient, 0.0))) * 10
        let transform = CGAffineTransform(scaleX: factor, y: factor)
        self.apply(transform)
        return self
    }

    func scale(usingScaleFactor factor: CGFloat) -> UIBezierPath {
        let transform = CGAffineTransform(scaleX: factor, y: factor)
        self.apply(transform)
        return self
    }

    func centered(to point: CGPoint) -> UIBezierPath {
        let center = bounds.center
        let centeredPoint = CGPoint(x: point.x - bounds.origin.x, y: point.y - bounds.origin.y)
        let vector = center.vector(to: centeredPoint)
        let transform = CGAffineTransform(translationX: vector.dx, y: vector.dy)
        apply(transform)
        return self
    }

    func getFactor(for rect: CGRect) -> CGFloat {
        let pathBounds = self.cgPath.boundingBox
        let scaledWidth = rect.width / pathBounds.width
        let scaledHeight = rect.height / pathBounds.height
        let factor = min(scaledWidth, max(scaledHeight, 0.0))
        return factor
    }
}

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: self.size.width / 2.0, y: self.size.height / 2.0)
    }
}

extension CGPoint {
    func vector(to point: CGPoint) -> CGVector {
        return CGVector(dx: point.x - self.x, dy: point.y - self.y)
    }
}
