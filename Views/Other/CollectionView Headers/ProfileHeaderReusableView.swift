//
//  ProfileHeaderCollectionReusableView.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 20.01.2022.
//

import SDWebImage
import UIKit

protocol ProfileHeaderDelegate: AnyObject {
    func profileHeaderDidTapPostsButton(_ header: ProfileHeaderReusableView)
    func profileHeaderDidTapFollowingButton(_ header: ProfileHeaderReusableView)
    func profileHeaderDidTapFollowersButton(_ header: ProfileHeaderReusableView)
    func profileHeaderDidTapEditProfileButton(_ header: ProfileHeaderReusableView)
}

final class ProfileHeaderReusableView: UICollectionReusableView {
    static let identifier = "ProfileHeaderCollectionReusableView"
    
    public weak var delegate: ProfileHeaderDelegate?
    
    private let profilePhotoWidthHeight: CGFloat = 90
    
    private let profilePhotoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .systemGray5
        return imageView
    }()
    
    private let postsButton: CustomButtonWithLabels = {
        let button = CustomButtonWithLabels()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let followingButton: CustomButtonWithLabels = {
        let button = CustomButtonWithLabels()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let followersButton: CustomButtonWithLabels = {
        let button = CustomButtonWithLabels()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var editProfileButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.setTitle("Edit Profile", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.cornerRadius = 5
        return button
    }()
    
    private lazy var followUnfollowButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Follow", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.cornerRadius = 5
        return button
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let bioLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews(profilePhotoImageView, postsButton, followingButton, followersButton, nameLabel, bioLabel)
        setupConstraints()
        setupButtonActions()
        profilePhotoImageView.layer.cornerRadius = profilePhotoWidthHeight / 2
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButtonActions() {
        postsButton.addTarget(self, action: #selector(didTapPostsButton), for: .touchUpInside)
        followingButton.addTarget(self, action: #selector(didTapFollowingButton), for: .touchUpInside)
        followersButton.addTarget(self, action: #selector(didTapFollowersButton), for: .touchUpInside)
        editProfileButton.addTarget(self, action: #selector(didTapEditProfileButton), for: .touchUpInside)
    }
    
    public func configure(name: String, bio: String, profilePicture: UIImage, postsCount: Int, followersCount: Int, followingCount: Int, isUserProfile: Bool) {
        profilePhotoImageView.image = profilePicture
        nameLabel.text = name
        bioLabel.text = bio
        postsButton.configureWith(labelText: "Posts", number: postsCount)
        followersButton.configureWith(labelText: "Followers", number: followersCount)
        followingButton.configureWith(labelText: "Following", number: followingCount)
        setupActionButton(isUserProfile: isUserProfile)
    }
    
    private func setupActionButton(isUserProfile: Bool) {
        if isUserProfile {
            addSubview(editProfileButton)
            NSLayoutConstraint.activate([
                editProfileButton.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 15),
                editProfileButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),
                editProfileButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15),
                editProfileButton.heightAnchor.constraint(equalToConstant: 30),
                editProfileButton.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor),
            ])
        } else {
            addSubview(followUnfollowButton)
            NSLayoutConstraint.activate([
                followUnfollowButton.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 15),
                followUnfollowButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),
                followUnfollowButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15),
                followUnfollowButton.heightAnchor.constraint(equalToConstant: 35),
                followUnfollowButton.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor),
            ])
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            profilePhotoImageView.heightAnchor.constraint(equalToConstant: profilePhotoWidthHeight),
            profilePhotoImageView.widthAnchor.constraint(equalToConstant: profilePhotoWidthHeight),
            profilePhotoImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            profilePhotoImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),
            
            postsButton.centerYAnchor.constraint(equalTo: profilePhotoImageView.centerYAnchor),
            postsButton.leadingAnchor.constraint(equalTo: profilePhotoImageView.trailingAnchor, constant: 15),
            postsButton.widthAnchor.constraint(equalToConstant: 70),
            postsButton.heightAnchor.constraint(equalToConstant: 45),
            
            followingButton.centerYAnchor.constraint(equalTo: postsButton.centerYAnchor),
            followingButton.leadingAnchor.constraint(equalTo: postsButton.trailingAnchor, constant: 10),
            followingButton.widthAnchor.constraint(equalToConstant: 70),
            followingButton.heightAnchor.constraint(equalToConstant: 45),
            
            followersButton.centerYAnchor.constraint(equalTo: followingButton.centerYAnchor),
            followersButton.leadingAnchor.constraint(equalTo: followingButton.trailingAnchor, constant: 15),
            followersButton.widthAnchor.constraint(equalToConstant: 70),
            followersButton.heightAnchor.constraint(equalToConstant: 45),
            
            nameLabel.topAnchor.constraint(equalTo: profilePhotoImageView.bottomAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: profilePhotoImageView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -15),
            nameLabel.heightAnchor.constraint(equalToConstant: 18),
            
            bioLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            bioLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            bioLabel.trailingAnchor.constraint(equalTo: followersButton.trailingAnchor),
        ])
    }
    
    @objc private func didTapPostsButton() {
        delegate?.profileHeaderDidTapPostsButton(self)
    }
    @objc private func didTapFollowingButton() {
        delegate?.profileHeaderDidTapFollowingButton(self)
    }
    @objc private func didTapFollowersButton() {
        delegate?.profileHeaderDidTapFollowersButton(self)
    }
    @objc private func didTapEditProfileButton() {
        delegate?.profileHeaderDidTapEditProfileButton(self)
    }
}

