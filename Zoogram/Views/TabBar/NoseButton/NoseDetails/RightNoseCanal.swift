//
//  RightNoseCanal.swift
//  CatNoseCALayer
//
//  Created by Artem Dolbiiev on 07.02.2024.
//

import UIKit

class RightNoseCanal: CAShapeLayer {

    init(in rect: CGRect, scaleFactor: CGFloat = 0) {
        super.init()
        createNoseCanal(with: rect, scaleFactor: scaleFactor)
        fillColor = UIColor.systemPink.cgColor
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createNoseCanal(with frame: CGRect, scaleFactor factor: CGFloat) {
        let rightCanal = UIBezierPath()
        rightCanal.move(to: CGPoint(x: 110.7, y: 7.3))
        rightCanal.addCurve(to: CGPoint(x: 117.7, y: 37.8), controlPoint1: CGPoint(x: 107.7, y: 14.8), controlPoint2: CGPoint(x: 107.7, y: 33.8))
        rightCanal.addCurve(to: CGPoint(x: 147.7, y: 13.3), controlPoint1: CGPoint(x: 134.7, y: 44.6), controlPoint2: CGPoint(x: 150.2, y: 21.3))
        rightCanal.addCurve(to: CGPoint(x: 128.7, y: 0.8), controlPoint1: CGPoint(x: 145.3, y: 5.3), controlPoint2: CGPoint(x: 137.7, y: 3.4))
        rightCanal.addCurve(to: CGPoint(x: 110.7, y: 7.3), controlPoint1: CGPoint(x: 124.3, y: -0.5), controlPoint2: CGPoint(x: 114.2, y: -1.2))
        rightCanal.close()

        let scaledPath = rightCanal.scale(usingScaleFactor: factor)
        let alignmentPoint = CGPoint(x: frame.maxX - (frame.maxX * 0.231), y: frame.maxY * 0.512)
        let alignedPath = align(path: scaledPath, to: alignmentPoint)
        self.path = alignedPath.cgPath
    }

    private func align(path: UIBezierPath, to point: CGPoint) -> UIBezierPath {
        let bound  = path.cgPath.boundingBoxOfPath
        let alignedPoint = CGPoint(x: point.x - bound.origin.x - (bound.width / 2), y: point.y - bound.midY)
        let transform = CGAffineTransform(translationX: alignedPoint.x, y: alignedPoint.y)
        path.apply(transform)
        return path
    }
}
