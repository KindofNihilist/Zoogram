//
//  FollowersListTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 21.01.2022.
//

import UIKit

@MainActor protocol FollowListCellDelegate: AnyObject {
    func removeButtonTapped(userID: String)
    func undoButtonTapped(userID: String)
    func followButtonTapped(userID: String)
    func unfollowButtonTapped(userID: String)
}

class FollowerTableViewCell: UITableViewCell {

    private var followStatus: FollowStatus!
    private var isFollowingMe: FollowStatus = .following

    private var userID: String!

    weak var delegate: FollowListCellDelegate?

    private let profileImageViewSize: CGFloat = 55

    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = .systemGray5
        return imageView
    }()

    let usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = CustomFonts.boldFont(ofSize: 14)
        label.textColor = Colors.label
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = CustomFonts.regularFont(ofSize: 14)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    private lazy var removeButton: HapticButton = {
        let button = HapticButton()
        button.setTitle(String(localized: "Remove"), for: .normal)
        button.setTitleColor(Colors.label, for: .normal)
        button.titleLabel?.font = CustomFonts.boldFont(ofSize: 14)
        button.backgroundColor = Colors.background
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
         button.titleLabel?.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 10).isActive = true
        button.titleLabel?.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -10).isActive = true
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.cornerRadius = 13
        button.layer.cornerCurve = .continuous
        button.addTarget(self, action: #selector(removeButtonTapped), for: .touchUpInside)
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return button
    }()

    private lazy var followUnfollowButton: HapticButton = {
        let button = HapticButton()
        button.setTitle(String(localized: "Follow"), for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = CustomFonts.boldFont(ofSize: 14)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapFollowUnfollowButton), for: .touchUpInside)
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViewsAndConstraints()
        selectionStyle = .none

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViewsAndConstraints() {
        contentView.addSubviews(profileImageView, removeButton, usernameLabel, nameLabel, followUnfollowButton)

        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            profileImageView.heightAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.widthAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),

            usernameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 5),
            usernameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            usernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: followUnfollowButton.leadingAnchor),

            nameLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 3),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: removeButton.leadingAnchor, constant: -10),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),

            followUnfollowButton.leadingAnchor.constraint(equalTo: usernameLabel.trailingAnchor, constant: 10),
            followUnfollowButton.trailingAnchor.constraint(lessThanOrEqualTo: removeButton.leadingAnchor, constant: -15),
            followUnfollowButton.heightAnchor.constraint(equalToConstant: 15),
            followUnfollowButton.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor),

            removeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            removeButton.heightAnchor.constraint(equalToConstant: 30),
            removeButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor)
        ])

        profileImageView.layer.cornerRadius = profileImageViewSize / 2
    }

    func configure(for user: ZoogramUser) {
        nameLabel.text = user.name
        usernameLabel.text = user.username
        profileImageView.image = user.getProfilePhoto() ?? UIImage.profilePicturePlaceholder
        self.followStatus = user.followStatus
        self.userID = user.userID
        switchFollowUnfollowButton(followStatus: followStatus)
    }

    private func switchFollowUnfollowButton(followStatus: FollowStatus) {
        switch followStatus {
        case .notFollowing:
            showFollowButton()
        case .following:
            showUnfollowButton()
        }
    }

    private func switchRemoveButton(followStatus: FollowStatus) {
        switch followStatus {
        case .following:
            removeButton.setTitle(String(localized: "Remove"), for: .normal)
        case .notFollowing:
            removeButton.setTitle(String(localized: "Undo"), for: .normal)
        }
    }

    private func showFollowButton() {
        followUnfollowButton.setTitle(String(localized: "Follow"), for: .normal)
        followUnfollowButton.setTitleColor(.systemBlue, for: .normal)
    }

    private func showUnfollowButton() {
        followUnfollowButton.setTitle(String(localized: "Unfollow"), for: .normal)
        followUnfollowButton.setTitleColor(Colors.label, for: .normal)
    }

    @objc func removeButtonTapped() {
        switch isFollowingMe {
        case .following:
            delegate?.removeButtonTapped(userID: userID)
            self.switchRemoveButton(followStatus: .notFollowing)
            self.isFollowingMe = .notFollowing
        case .notFollowing:
            delegate?.undoButtonTapped(userID: userID)
            self.switchRemoveButton(followStatus: .following)
            self.isFollowingMe = .following
        }
    }

    @objc func didTapFollowUnfollowButton() {
        switch followStatus {
        case .notFollowing:
            delegate?.followButtonTapped(userID: self.userID)
            self.followStatus = .following
            self.switchFollowUnfollowButton(followStatus: .following)
        case .following:
            delegate?.unfollowButtonTapped(userID: self.userID)
            self.followStatus = .notFollowing
            self.switchFollowUnfollowButton(followStatus: .notFollowing)
        default:
            return
        }
    }
}
