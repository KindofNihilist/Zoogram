//
//  UIView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 01.11.2023.
//

import UIKit

extension UIView {
    func addSubviews(_ views: UIView...) {
        for view in views {
            addSubview(view)
        }
    }

    func removeSubviews(_ views: UIView...) {
        for view in views {
            view.removeFromSuperview()
        }
    }

    func shakeByX(offset: CGFloat, repeatCount: Int, durationOfOneCycle: CGFloat) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = durationOfOneCycle
        animation.repeatCount = Float(repeatCount)
        animation.autoreverses = true
        animation.fromValue = CGPoint(x: self.center.x - offset, y: self.center.y)
        animation.toValue = CGPoint(x: self.center.x + offset, y: self.center.y)
        self.layer.add(animation, forKey: "position")
    }

    func shakeByY(offset: CGFloat, repeatCount: Int, durationOfOneCycle: CGFloat) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = durationOfOneCycle
        animation.repeatCount = Float(repeatCount)
        animation.autoreverses = true
        animation.fromValue = CGPoint(x: self.center.x, y: self.center.y - offset)
        animation.toValue = CGPoint(x: self.center.x, y: self.center.y + offset)
        self.layer.add(animation, forKey: "position")
    }
}
