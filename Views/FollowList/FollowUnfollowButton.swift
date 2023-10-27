//
//  FollowButton.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.02.2023.
//

import UIKit

class FollowUnfollowButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        self.layer.cornerRadius = 10
        self.layer.cornerCurve = .continuous
        self.clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func changeAppearenceToFollow() {
        self.setTitle("Follow", for: .normal)
        self.setTitleColor(.white, for: .normal)
        self.backgroundColor = .systemBlue
        self.layer.borderWidth = 0
        self.layer.borderColor = .none
    }

    func changeAppearenceToUnfollow() {
        self.setTitle("Unfollow", for: .normal)
        self.backgroundColor = .systemBackground
        self.setTitleColor(.label, for: .normal)
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.lightGray.cgColor
    }

}
