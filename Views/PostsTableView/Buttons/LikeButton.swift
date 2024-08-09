//
//  LikeButton.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 12.05.2023.
//

import UIKit

class LikeButton: UIButton {

    var buttonState: LikeState = .notLiked
    var unlikedStateImage = UIImage(named: "heartIcon")
    var likedStateImage = UIImage(named: "heartFilledIcon")

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setImage(unlikedStateImage, for: .normal)
        self.imageView?.contentMode = .scaleAspectFit
        self.tintColor = Colors.label
        self.contentHorizontalAlignment = .fill
        self.contentVerticalAlignment = .fill
        self.isOpaque = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setLikeButtonState(likeState: LikeState, isUserInitiated: Bool) {
        switch likeState {
        case .liked:
            showLikedButton(animated: isUserInitiated)
        case .notLiked:
            showLikeButton(animated: isUserInitiated)
        }
        self.buttonState = likeState
    }

    func showLikeButton(animated: Bool = true) {
        if animated {

            UIView.animate(withDuration: 0.1) {
                self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            } completion: { _ in
                self.setImage(self.unlikedStateImage, for: .normal)
                UIView.animate(withDuration: 0.1) {
                    self.transform = .identity
                    self.tintColor = Colors.label
                }
            }
        } else {
            self.setImage(self.unlikedStateImage, for: .normal)
            self.tintColor = Colors.label
        }
    }

    func showLikedButton(animated: Bool = true) {
        if animated {

            UIView.animate(withDuration: 0.1) {
                self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            } completion: { _ in
                self.setImage(self.likedStateImage, for: .normal)
                UIView.animate(withDuration: 0.1) {
                    self.transform = .identity
                    self.tintColor = Colors.heartRed
                }
            }
        } else {
            self.setImage(self.likedStateImage, for: .normal)
            self.tintColor = Colors.heartRed
        }
    }
}
