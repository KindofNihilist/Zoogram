//
//  CatNoseShape.swift
//  CatNoseCALayer
//
//  Created by Artem Dolbiiev on 02.02.2024.
//

import UIKit

class CatNoseShape: CAShapeLayer {

    init(in rect: CGRect) {
        super.init()
        self.fillColor = Colors.activeCatNoseColorScheme.noseColor.cgColor
        createNoseShape(in: rect)
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateFrame(_ frame: CGRect) {
        createNoseShape(in: frame)
    }

    private func createNoseShape(in rect: CGRect) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 131.8, y: 101.5))
        path.addCurve(to: CGPoint(x: 61.8, y: 101.5), controlPoint1: CGPoint(x: 116.8, y: 150.5), controlPoint2: CGPoint(x: 76.8, y: 150.5))
        path.addCurve(to: CGPoint(x: 24.8, y: 67.5), controlPoint1: CGPoint(x: 56.6, y: 89.5), controlPoint2: CGPoint(x: 57.2, y: 81.4))
        path.addCurve(to: CGPoint(x: 2.8, y: 38), controlPoint1: CGPoint(x: 1.3, y: 58.7), controlPoint2: CGPoint(x: -4.2, y: 45.5))
        path.addCurve(to: CGPoint(x: 32.3, y: 12), controlPoint1: CGPoint(x: 11, y: 28.3), controlPoint2: CGPoint(x: 23.3, y: 14))
        path.addCurve(to: CGPoint(x: 157.8, y: 12), controlPoint1: CGPoint(x: 86.8, y: -4), controlPoint2: CGPoint(x: 106.8, y: -4))
        path.addCurve(to: CGPoint(x: 190.8, y: 38), controlPoint1: CGPoint(x: 166.8, y: 14), controlPoint2: CGPoint(x: 182.6, y: 28.3))
        path.addCurve(to: CGPoint(x: 168.8, y: 67.5), controlPoint1: CGPoint(x: 197.8, y: 45.5), controlPoint2: CGPoint(x: 192.3, y: 58.7))
        path.addCurve(to: CGPoint(x: 131.8, y: 101.5), controlPoint1: CGPoint(x: 136.4, y: 81.4), controlPoint2: CGPoint(x: 137, y: 89.5))
        path.close()
        self.path = path.scaledToFit(rect: rect).centered(to: rect.center).cgPath
    }
}
