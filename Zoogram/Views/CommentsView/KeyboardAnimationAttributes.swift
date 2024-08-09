//
//  KeyboardAnimationAttributes.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 21.06.2024.
//

import UIKit
import Foundation

@MainActor
struct KeyboardAnimationAttributes {

    var beginKeyboardSize: CGRect
    var endKeyboardSize: CGRect
    var keyboardAnimationDuration: Double
    var keyboardAnimationCurve: UIView.AnimationCurve

    init?(notification: NSNotification) {
        guard let beginKeyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue,
              let endKeyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let keyboardAnimationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let animationCurve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
              let keyboardAnimationCurve = UIView.AnimationCurve(rawValue: animationCurve)
        else {
            return nil
        }
        self.beginKeyboardSize = beginKeyboardSize
        self.endKeyboardSize = endKeyboardSize
        self.keyboardAnimationDuration = keyboardAnimationDuration
        self.keyboardAnimationCurve = keyboardAnimationCurve
    }
}
