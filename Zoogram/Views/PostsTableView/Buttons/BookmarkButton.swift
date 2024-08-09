//
//  self.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 12.05.2023.
//

import UIKit

class BookmarkButton: UIButton {

    var buttonState: BookmarkState = .notBookmarked
    var generator = UIImpactFeedbackGenerator(style: .medium)
    var unbookmarkedStateImage = UIImage(named: "unbookmarkedIcon")
    var bookmarkedStateImage = UIImage(named: "bookmarkedIcon")

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setImage(unbookmarkedStateImage, for: .normal)
        self.imageView?.contentMode = .scaleAspectFit
        self.contentHorizontalAlignment = .fill
        self.contentVerticalAlignment = .fill
        self.isOpaque = true
        self.backgroundColor = Colors.background
        self.tintColor = Colors.label
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if buttonState == .bookmarked {
            generator.prepare()
            generator.impactOccurred()
        }
    }

    func setBookmarkButtonState(state: BookmarkState, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.1) {
                self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            } completion: { _ in
                if state == .bookmarked {
                    self.setBookmarkedState()
                } else {
                    self.setUnmarkedState()
                }
                UIView.animate(withDuration: 0.1) {
                    self.transform = .identity
                }
            }
        } else {
            if state == .bookmarked {
                setBookmarkedState()
            } else {
                setUnmarkedState()
            }
        }
        self.buttonState = state
    }

    func setBookmarkedState() {
        self.setImage(bookmarkedStateImage, for: .normal)
        self.tintColor = Colors.bookmarked
    }

    func setUnmarkedState() {
        self.setImage(unbookmarkedStateImage, for: .normal)
        self.tintColor = Colors.unbookmarked
    }
}
