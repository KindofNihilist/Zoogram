//
//  customButton.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 12.10.2022.
//

import UIKit

class CustomButton: UIButton {

    var shouldIgnoreOwnAnimations: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.titleLabel?.font = CustomFonts.boldFont(ofSize: 18)
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 13
        self.layer.cornerCurve = .continuous
        self.setTitleColor(.white, for: .normal)
        self.backgroundColor = .systemBlue
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if shouldIgnoreOwnAnimations == false {
            UIView.animate(withDuration: 0.1) {
                self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if shouldIgnoreOwnAnimations == false {
            UIView.animate(withDuration: 0.1) {
                self.transform = CGAffineTransform.identity
            }
        }
    }
}
