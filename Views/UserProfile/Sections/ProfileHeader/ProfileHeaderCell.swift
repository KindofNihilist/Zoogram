//
//  ProfileHeaderCollectionReusableView.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 20.01.2022.
//

import SDWebImage
import UIKit

protocol ProfileHeaderDelegate: AnyObject {
    func postsButtonTapped()
    func followingButtonTapped()
    func followersButtonTapped()
    func editProfileButtonTapped()
    func followButtonTapped(completion: @escaping (FollowStatus) -> Void)
    func unfollowButtonTapped(completion: @escaping (FollowStatus) -> Void)
}

final class ProfileHeaderCell: UICollectionViewCell {

    weak var delegate: ProfileHeaderDelegate?

    lazy var followStatus: FollowStatus = .notFollowing

    private let profilePhotoSize = CGSize(width: 90, height: 90)

    private let profilePhotoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .systemGray5
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
    }

    override func layoutSubviews() {
        profilePhotoImageView.layer.cornerRadius = profilePhotoSize.height / 2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureWith(viewModel: UserProfileViewModel) {
        let user = viewModel.user
        self.followStatus = user.followStatus
        profilePhotoImageView.image = user.profilePhoto ?? UIImage()
        nameLabel.text = user.name
        bioLabel.text = user.bio
        postsButton.configureWith(labelText: "Posts", number: viewModel.postsCount)
        followersButton.configureWith(labelText: "Followers", number: viewModel.followersCount)
        followingButton.configureWith(labelText: "Following", number: viewModel.followingCount)
        setupActionButton(isUserProfile: viewModel.isCurrentUserProfile, followStatus: user.followStatus)

        addSubviews(profilePhotoImageView, upperButtonsRow, nameLabel, bioLabel, actionButton)
        upperButtonsRow.addArrangedSubviews(postsButton, followingButton, followersButton)
        setupConstraints()
    }

//    func changeFollowingCount(followingCount: Int) {
//        followingButton.configureWith(labelText: "Following", number: followingCount)
//    }
//
//    func changeFollowersCount(followersCount: Int) {
//        followersButton.configureWith(labelText: "Following", number: followersCount)
//    }

    func setupActionButtonAsEditButton() {
        actionButton.titleLabel?.font = CustomFonts.boldFont(ofSize: 15)
        actionButton.setTitle("Edit Profile", for: .normal)
        actionButton.setTitleColor(.label, for: .normal)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.layer.borderWidth = 0.5
        actionButton.layer.borderColor = UIColor.lightGray.cgColor
        actionButton.layer.cornerRadius = 10
        actionButton.layer.cornerCurve = .continuous
        actionButton.addTarget(self, action: #selector(didTapEditProfileButton), for: .touchUpInside)
    }

    func setupActionButtonAsFollowButton() {
        actionButton.titleLabel?.font = CustomFonts.boldFont(ofSize: 16)
        actionButton.setTitle("Follow", for: .normal)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.backgroundColor = .systemBlue
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.layer.borderWidth = 0.5
        actionButton.layer.borderColor = UIColor.lightGray.cgColor
        actionButton.layer.cornerRadius = 10
        actionButton.layer.cornerCurve = .continuous
        actionButton.addTarget(self, action: #selector(didTapFollowUnfollowButton), for: .touchUpInside)
        switchFollowStatus(status: followStatus)
    }

    func switchFollowStatus(status: FollowStatus) {
        self.followStatus = status
        switch status {
        case .notFollowing:
            actionButton.setTitle("Follow", for: .normal)
            actionButton.backgroundColor = .systemBlue
            actionButton.setTitleColor(.white, for: .normal)

        case .following:
            actionButton.setTitle("Unfollow", for: .normal)
            actionButton.backgroundColor = .systemBackground
            actionButton.setTitleColor(.label, for: .normal)
        }
    }

    private func setupActionButton(isUserProfile: Bool, followStatus: FollowStatus) {
        if isUserProfile {
            setupActionButtonAsEditButton()
        } else {
            setupActionButtonAsFollowButton()
        }
    }

// MARK: Constraints Setup
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            profilePhotoImageView.heightAnchor.constraint(equalToConstant: profilePhotoSize.height),
            profilePhotoImageView.widthAnchor.constraint(equalToConstant: profilePhotoSize.width),
            profilePhotoImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            profilePhotoImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),

            upperButtonsRow.topAnchor.constraint(equalTo: profilePhotoImageView.topAnchor),
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
            bioLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),

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
        print("eddit button tapped")
        delegate?.editProfileButtonTapped()
    }
    @objc private func didTapFollowUnfollowButton() {
        switch followStatus {

        case .notFollowing:
            delegate?.followButtonTapped { [weak self] followStatus in
                self?.switchFollowStatus(status: followStatus)
            }

        case .following:
            delegate?.unfollowButtonTapped { [weak self] followStatus in
                self?.switchFollowStatus(status: followStatus)
            }
        }
    }
}
