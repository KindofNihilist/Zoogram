//
//  LikeButton.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 12.05.2023.
//

import UIKit


class LikeButton: UIButton {

    var buttonState: LikeState = .notLiked
//    var unlikedStateImage = UIImage(systemName: "heartIcon", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28))
    var unlikedStateImage = UIImage(named: "heartIcon")
    var likedStateImage = UIImage(named: "heartFilledIcon")
//    var likedStateImage = UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28))

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setImage(unlikedStateImage, for: .normal)
        self.imageView?.contentMode = .scaleAspectFit
        self.tintColor = .label
        self.contentHorizontalAlignment = .fill
        self.contentVerticalAlignment = .fill
//        self.backgroundColor = .systemGreen
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
    }

    func showLikeButton(animated: Bool = true) {
        if animated {

            UIView.animate(withDuration: 0.1) {
                self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            } completion: { _ in
                self.setImage(self.unlikedStateImage, for: .normal)
                UIView.animate(withDuration: 0.1) {
                    self.transform = .identity
                    self.tintColor = .label
                }
            }
        } else {
            self.setImage(self.unlikedStateImage, for: .normal)
            self.tintColor = .label
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
                    self.tintColor = .systemRed
                }
            }
        } else {
            self.setImage(self.likedStateImage, for: .normal)
            self.tintColor = .systemRed
        }
    }
}
