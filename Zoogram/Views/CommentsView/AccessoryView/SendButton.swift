//
//  PostButton.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.06.2024.
//

import UIKit.UIButton

class SendButton: UIButton {

    private let hapticNotificationGenerator = UINotificationFeedbackGenerator()
    private let hapticTouchGenerator = UIImpactFeedbackGenerator()

    var action: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
        self.layer.cornerRadius = 30/2
        self.setImage(UIImage(systemName: "arrow.up.circle.fill",
                                withConfiguration: UIImage.SymbolConfiguration(pointSize: 35)), for: .normal)
        self.tintColor = Colors.coolBlue
        self.addTarget(self, action: #selector(didTapSendButton), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        hapticTouchGenerator.prepare()
        let intensity = 0.6
        if #available(iOS 17.5, *) {
            hapticTouchGenerator.impactOccurred(intensity: intensity, at: self.frame.center)
        } else {
            hapticTouchGenerator.impactOccurred(intensity: intensity)
        }
    }

    @objc private func didTapSendButton() {
        action?()
    }

    func performSuccessfulFeedback() {
        if #available(iOS 17.5, *) {
            hapticNotificationGenerator.notificationOccurred(.success, at: self.frame.center)
        } else {
            hapticNotificationGenerator.notificationOccurred(.success)
        }
    }
}
