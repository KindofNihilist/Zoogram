//
//  NoseMiddleFoldShape.swift
//  CatNoseCALayer
//
//  Created by Artem Dolbiiev on 06.02.2024.
//

import UIKit

class NoseMiddleFoldShape: CAShapeLayer {

    init(in rect: CGRect) {
        super.init()
        fillColor = UIColor.systemOrange.cgColor
        createNoseFold(in: rect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateFrame(_ frame: CGRect) {
        self.createNoseFold(in: frame)
    }

    private func createNoseFold(in rect: CGRect) {
        let adoptedRect = CGRect(x: rect.maxX, y: rect.maxY, width: rect.width * 0.8, height: rect.height * 0.8)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 97, y: 29))
        path.addCurve(to: CGPoint(x: 94.8, y: 138), controlPoint1: CGPoint(x: 94.5, y: 29.9), controlPoint2: CGPoint(x: 93, y: 137.7))
        path.addCurve(to: CGPoint(x: 99.2, y: 138), controlPoint1: CGPoint(x: 96.6, y: 138.3), controlPoint2: CGPoint(x: 97.3, y: 138.3))
        path.addCurve(to: CGPoint(x: 97, y: 29), controlPoint1: CGPoint(x: 101, y: 137.7), controlPoint2: CGPoint(x: 99.5, y: 28.1))
        path.close()

        let scaledPath = path.scaledToFit(rect: adoptedRect)
        let yPoint = rect.maxY - rect.minY
        let xPoint = rect.midX - rect.minX
        let alignedPath = align(path: scaledPath, to: CGPoint(x: xPoint, y: yPoint))
        self.path = alignedPath.cgPath
    }

    private func align(path: UIBezierPath, to point: CGPoint) -> UIBezierPath {
        let bound  = path.cgPath.boundingBoxOfPath
        let alignedPoint = CGPoint(x: point.x - bound.origin.x - (bound.width / 2), y: point.y - bound.maxY)
        let transform = CGAffineTransform(translationX: alignedPoint.x, y: alignedPoint.y)
        path.apply(transform)
        return path
    }
}
