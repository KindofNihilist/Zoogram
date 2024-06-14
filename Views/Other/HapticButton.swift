//
//  HapticButton.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 04.03.2024.
//

import UIKit.UIButton

class HapticButton: UIButton {

    private let hapticGenerator = UIImpactFeedbackGenerator(style: .rigid)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        hapticGenerator.prepare()
        hapticGenerator.impactOccurred(intensity: 0.4)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        hapticGenerator.prepare()
        hapticGenerator.impactOccurred(intensity: 1.0)
    }
}
