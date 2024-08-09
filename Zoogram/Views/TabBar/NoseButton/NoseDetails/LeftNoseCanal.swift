//
//  NoseCanals.swift
//  CatNoseCALayer
//
//  Created by Artem Dolbiiev on 07.02.2024.
//

import UIKit

class LeftNoseCanal: CAShapeLayer {

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
        let leftCanal = UIBezierPath()
        leftCanal.move(to: CGPoint(x: 37.3, y: 7.3))
        leftCanal.addCurve(to: CGPoint(x: 30.3, y: 37.8), controlPoint1: CGPoint(x: 40.3, y: 14.8), controlPoint2: CGPoint(x: 40.3, y: 33.8))
        leftCanal.addCurve(to: CGPoint(x: 0.3, y: 13.3), controlPoint1: CGPoint(x: 13.3, y: 44.6), controlPoint2: CGPoint(x: -2.2, y: 21.3))
        leftCanal.addCurve(to: CGPoint(x: 19.3, y: 0.8), controlPoint1: CGPoint(x: 2.7, y: 5.3), controlPoint2: CGPoint(x: 10.3, y: 3.4))
        leftCanal.addCurve(to: CGPoint(x: 37.3, y: 7.3), controlPoint1: CGPoint(x: 23.7, y: -0.5), controlPoint2: CGPoint(x: 33.8, y: -1.2))
        leftCanal.close()

        let scaledPath = leftCanal.scale(usingScaleFactor: factor)
        let alignmentPoint = CGPoint(x: frame.maxX * 0.222, y: frame.maxY * 0.512)
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
