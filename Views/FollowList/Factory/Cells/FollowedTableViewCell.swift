//
//  FollowingListTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 21.01.2022.
//

import UIKit

class FollowedTableViewCell: UITableViewCell {

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
        label.numberOfLines = 1
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

    private lazy var followUnfollowButton: FollowUnfollowButton = {
        let button = FollowUnfollowButton(followStatus: .notFollowing)
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
        contentView.addSubviews(profileImageView, followUnfollowButton, usernameLabel, nameLabel)

        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            profileImageView.heightAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.widthAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

            usernameLabel.topAnchor.constraint(lessThanOrEqualTo: profileImageView.topAnchor, constant: 5),
            usernameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            usernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: followUnfollowButton.leadingAnchor, constant: -10),

            nameLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 3),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            nameLabel.trailingAnchor.constraint(equalTo: followUnfollowButton.leadingAnchor, constant: -10),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: profileImageView.bottomAnchor),

            followUnfollowButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            followUnfollowButton.heightAnchor.constraint(equalToConstant: 30),
            followUnfollowButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor)
        ])
        profileImageView.layer.cornerRadius = profileImageViewSize / 2
    }

    func configure(user: ZoogramUser) {
        if user.userID == UserManager.shared.getUserID() {
            followUnfollowButton.isHidden = true
            followUnfollowButton.isEnabled = false
        }
        nameLabel.text = user.name
        usernameLabel.text = user.username
        profileImageView.image = user.getProfilePhoto()
        self.userID = user.userID
        if let followStatus = user.followStatus {
            followUnfollowButton.followStatus = followStatus
        }
    }

    @objc func didTapFollowUnfollowButton() {

        switch followUnfollowButton.followStatus {
        case .notFollowing:
            delegate?.followButtonTapped(userID: self.userID) { status in
                self.followUnfollowButton.followStatus = status
            }

        case .following:
            delegate?.unfollowButtonTapped(userID: self.userID) { status in
                self.followUnfollowButton.followStatus = status
            }
        }
    }
}
