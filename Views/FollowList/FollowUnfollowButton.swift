//
//  FollowButton.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.02.2023.
//

import UIKit

class FollowUnfollowButton: HapticButton {

    var followStatus: FollowStatus {
        didSet {
            self.switchFollowStatus(status: followStatus)
        }
    }

    init(followStatus: FollowStatus) {
        self.followStatus = followStatus
        super.init(frame: CGRect.zero)
        self.titleLabel?.font = CustomFonts.boldFont(ofSize: 15)
        self.titleLabel?.adjustsFontSizeToFitWidth = true
        self.titleLabel?.minimumScaleFactor = 0.5
        self.titleLabel?.textAlignment = .center
        self.layer.cornerRadius = 13
        self.layer.cornerCurve = .continuous
        self.clipsToBounds = true
        self.titleLabel?.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10).isActive = true
        self.titleLabel?.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
        switchFollowStatus(status: followStatus)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func switchFollowStatus(status: FollowStatus) {
        switch status {
        case .notFollowing:
            changeAppearenceToFollow()
        case .following:
            changeAppearenceToUnfollow()
        }
    }

    func changeAppearenceToFollow() {
        self.setTitle(String(localized: "Follow"), for: .normal)
        self.setTitleColor(.white, for: .normal)
        self.backgroundColor = Colors.coolBlue
    }

    func changeAppearenceToUnfollow() {
        self.setTitle(String(localized: "Unfollow"), for: .normal)
        self.backgroundColor = Colors.backgroundSecondary
        self.setTitleColor(Colors.label, for: .normal)
    }
}
