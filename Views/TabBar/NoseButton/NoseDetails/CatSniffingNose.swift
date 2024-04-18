//
//  CatSniffingNose.swift
//  CatNoseCALayer
//
//  Created by Artem Dolbiiev on 07.02.2024.
//

import UIKit

class CatSniffingNose: CAShapeLayer {

    var scaleFactor: CGFloat = 0

    init(in frame: CGRect) {
        super.init()
        self.fillColor = Colors.activeCatNoseColorScheme.noseColor.cgColor
        createNoseShape(in: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateFrame(_ frame: CGRect) {
        createNoseShape(in: frame)
    }

    private func createNoseShape(in frame: CGRect) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 130.8, y: 101.5))
        path.addCurve(to: CGPoint(x: 60.8, y: 101.5), controlPoint1: CGPoint(x: 131, y: 149.5), controlPoint2: CGPoint(x: 60.8, y: 149.5))
        path.addCurve(to: CGPoint(x: 31.3, y: 69), controlPoint1: CGPoint(x: 62.5, y: 90), controlPoint2: CGPoint(x: 72.5, y: 52))
        path.addCurve(to: CGPoint(x: 1.5, y: 38), controlPoint1: CGPoint(x: -1.1, y: 82.4), controlPoint2: CGPoint(x: -0.8, y: 45.7))
        path.addCurve(to: CGPoint(x: 24, y: 12), controlPoint1: CGPoint(x: 4.7, y: 27.5), controlPoint2: CGPoint(x: 15, y: 14))
        path.addCurve(to: CGPoint(x: 168, y: 12), controlPoint1: CGPoint(x: 78.5, y: -4), controlPoint2: CGPoint(x: 117, y: -4))
        path.addCurve(to: CGPoint(x: 190.5, y: 38), controlPoint1: CGPoint(x: 177, y: 14), controlPoint2: CGPoint(x: 187.3, y: 27.5))
        path.addCurve(to: CGPoint(x: 160.8, y: 69), controlPoint1: CGPoint(x: 192.9, y: 45.7), controlPoint2: CGPoint(x: 193, y: 82.5))
        path.addCurve(to: CGPoint(x: 130.8, y: 101.5), controlPoint1: CGPoint(x: 119.5, y: 52), controlPoint2: CGPoint(x: 129.5, y: 90))
        path.close()
        self.scaleFactor = path.getFactor(for: frame)
        self.path = path.scaledToFit(rect: frame).centered(to: frame.center).cgPath
    }
}
