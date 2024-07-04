//
//  ProfileHeaderCollectionReusableView.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 20.01.2022.
//

import SDWebImage
import UIKit

@MainActor protocol ProfileHeaderDelegate: AnyObject {
    func postsButtonTapped()
    func followingButtonTapped()
    func followersButtonTapped()
    func editProfileButtonTapped()
    func followButtonTapped()
    func unfollowButtonTapped()
}

final class ProfileHeaderCell: UICollectionViewCell {

    weak var delegate: ProfileHeaderDelegate?

    private let profilePhotoSize = CGSize(width: 90, height: 90)

    private let profilePhotoImageView: ProfilePictureImageView = {
        let imageView = ProfilePictureImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var postsButton: CustomButtonWithLabels = {
        let button = CustomButtonWithLabels()
        button.addTarget(self, action: #selector(didTapPostsButton), for: .touchUpInside)
        return button
    }()

    private lazy var followingButton: CustomButtonWithLabels = {
        let button = CustomButtonWithLabels()
        button.addTarget(self, action: #selector(didTapFollowingButton), for: .touchUpInside)
        return button
    }()

    private lazy var followersButton: CustomButtonWithLabels = {
        let button = CustomButtonWithLabels()
        button.addTarget(self, action: #selector(didTapFollowersButton), for: .touchUpInside)
        return button
    }()

    private lazy var upperButtonsRow: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = CustomFonts.boldFont(ofSize: 15)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let bioLabel: UILabel = {
        let label = UILabel()
        label.font = CustomFonts.regularFont(ofSize: 15)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        return label
    }()

    private var actionButton = UIButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = Colors.background
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        profilePhotoImageView.layer.cornerRadius = profilePhotoSize.height / 2
        print("bio frame size: \(bioLabel.frame.height)")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.actionButton.layer.borderColor = Colors.label.cgColor
    }

    func configureWith(viewModel: UserProfileViewModel) {
        profilePhotoImageView.image = viewModel.profileImage
        nameLabel.text = viewModel.name
        setupBio(bio: viewModel.bio)
        postsButton.configureWith(labelText: String(localized: "Posts"), number: viewModel.postsCount)
        followersButton.configureWith(labelText: String(localized: "Followers"), number: viewModel.followersCount)
        followingButton.configureWith(labelText: String(localized: "Following"), number: viewModel.followedUsersCount)
        setupActionButton(isUserProfile: viewModel.isCurrentUserProfile, followStatus: viewModel.followStatus)
        addSubviews(profilePhotoImageView, upperButtonsRow, nameLabel, bioLabel, actionButton)
        upperButtonsRow.addArrangedSubviews(postsButton, followersButton, followingButton)
        setupConstraints()
    }

    private func setupBio(bio: String?) {
        guard let bio = bio,
              bio.isEmpty == false
        else {
            bioLabel.isHidden = true
            return
        }
        bioLabel.isHidden = false
        bioLabel.text = bio
    }

    private func setupActionButtonAsEditButton() {
        actionButton.titleLabel?.font = CustomFonts.boldFont(ofSize: 15)
        actionButton.setTitle(String(localized: "Edit Profile"), for: .normal)
        actionButton.setTitleColor(Colors.label, for: .normal)
        actionButton.backgroundColor = Colors.backgroundSecondary
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.layer.cornerRadius = 10
        actionButton.layer.cornerCurve = .continuous
        actionButton.addTarget(self, action: #selector(didTapEditProfileButton), for: .touchUpInside)
    }

    private func setupActionButtonAsFollowButton(followStatus: FollowStatus) {
        actionButton = FollowUnfollowButton(followStatus: followStatus)
        actionButton.titleLabel?.font = CustomFonts.boldFont(ofSize: 16)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(didTapFollowUnfollowButton), for: .touchUpInside)
    }

    private func setupActionButton(isUserProfile: Bool, followStatus: FollowStatus?) {
        if isUserProfile {
            setupActionButtonAsEditButton()
        } else if let followStatus = followStatus {
            setupActionButtonAsFollowButton(followStatus: followStatus)
        }
    }

// MARK: Constraints Setup
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            profilePhotoImageView.heightAnchor.constraint(equalToConstant: profilePhotoSize.height),
            profilePhotoImageView.widthAnchor.constraint(equalToConstant: profilePhotoSize.width),
            profilePhotoImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            profilePhotoImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),

            upperButtonsRow.topAnchor.constraint(greaterThanOrEqualTo: profilePhotoImageView.topAnchor),
            upperButtonsRow.centerYAnchor.constraint(equalTo: profilePhotoImageView.centerYAnchor),
            upperButtonsRow.leadingAnchor.constraint(equalTo: profilePhotoImageView.trailingAnchor, constant: 15),
            upperButtonsRow.heightAnchor.constraint(equalToConstant: 45),
            upperButtonsRow.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15),

            nameLabel.topAnchor.constraint(equalTo: profilePhotoImageView.bottomAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: profilePhotoImageView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: upperButtonsRow.trailingAnchor, constant: -15),
            nameLabel.heightAnchor.constraint(equalToConstant: 18),

            bioLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            bioLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            bioLabel.trailingAnchor.constraint(equalTo: upperButtonsRow.trailingAnchor),

            actionButton.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 20),
            actionButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),
            actionButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15),
            actionButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -25),
            actionButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc private func didTapPostsButton() {
        delegate?.postsButtonTapped()
    }
    @objc private func didTapFollowingButton() {
        delegate?.followingButtonTapped()
    }
    @objc private func didTapFollowersButton() {
        delegate?.followersButtonTapped()
    }
    @objc private func didTapEditProfileButton() {
        delegate?.editProfileButtonTapped()
    }
    @objc private func didTapFollowUnfollowButton() {
        guard let followButton = self.actionButton as? FollowUnfollowButton else {
            return
        }

        switch followButton.followStatus {
        case .notFollowing:
            delegate?.followButtonTapped()
            followButton.followStatus = .following
        case .following:
            delegate?.unfollowButtonTapped()
            followButton.followStatus = .notFollowing
        }
    }
}
