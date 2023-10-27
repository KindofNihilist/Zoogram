//
//  self.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 12.05.2023.
//

import UIKit

class BookmarkButton: UIButton {

    var buttonState: BookmarkState = .notBookmarked
//    var unbookmarkedStateImage = UIImage(systemName: "bookmarkIcon", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28))
    var unbookmarkedStateImage = UIImage(named: "unbookmarkedIcon")
    var bookmarkedStateImage = UIImage(named: "bookmarkedIcon")
//    var bookmarkedStateImage = UIImage(systemName: "bookmark.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28))

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setImage(unbookmarkedStateImage, for: .normal)
        self.imageView?.contentMode = .scaleAspectFit
        self.contentHorizontalAlignment = .fill
        self.contentVerticalAlignment = .fill
        self.isOpaque = true
        self.backgroundColor = .systemBackground
        self.tintColor = .label
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    }

    func setBookmarkedState() {
        self.setImage(bookmarkedStateImage, for: .normal)
    }

    func setUnmarkedState() {
        self.setImage(unbookmarkedStateImage, for: .normal)
    }
}
