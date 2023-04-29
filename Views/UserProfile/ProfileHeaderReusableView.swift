//
//  ProfileHeaderCollectionReusableView.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 20.01.2022.
//

import SDWebImage
import UIKit

protocol ProfileHeaderDelegate: AnyObject {
    func postsButtonTapped(_ header: ProfileHeaderReusableView)
    func followingButtonTapped(_ header: ProfileHeaderReusableView)
    func followersButtonTapped(_ header: ProfileHeaderReusableView)
    func editProfileButtonTapped(_ header: ProfileHeaderReusableView)
    func followButtonTapped(_ header: ProfileHeaderReusableView)
    func unfollowButtonTapped(_ header: ProfileHeaderReusableView)
}

final class ProfileHeaderReusableView: UICollectionReusableView {
    static let identifier = "ProfileHeaderCollectionReusableView"
    
    lazy var followStatus: FollowStatus = .notFollowing
    
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
        button.addTarget(self, action: #selector(didTapPostsButton), for: .touchUpInside)
        return button
    }()
    
    private let followingButton: CustomButtonWithLabels = {
        let button = CustomButtonWithLabels()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapFollowingButton), for: .touchUpInside)
        return button
    }()
    
    private let followersButton: CustomButtonWithLabels = {
        let button = CustomButtonWithLabels()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapFollowersButton), for: .touchUpInside)
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
        button.addTarget(self, action: #selector(didTapEditProfileButton), for: .touchUpInside)
        button.isHidden = true
        button.isEnabled = false
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
        button.addTarget(self, action: #selector(didTapFollowUnfollowButton), for: .touchUpInside)
        button.isHidden = true
        button.isEnabled = false
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
        addSubviews(profilePhotoImageView, postsButton, followingButton, followersButton, nameLabel, bioLabel, editProfileButton, followUnfollowButton)
        setupConstraints()
        profilePhotoImageView.layer.cornerRadius = profilePhotoWidthHeight / 2
        clipsToBounds = true
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
    }
    
    func changeFollowingCount(followingCount: Int) {
        followingButton.configureWith(labelText: "Following", number: followingCount)
    }
    
    func changeFollowersCount(followersCount: Int) {
        followersButton.configureWith(labelText: "Following", number: followersCount)
    }
    
    func switchFollowUnfollowButton(followStatus: FollowStatus) {
        self.followStatus = followStatus
        switch followStatus {
        case .notFollowing:
            print("Showing follow button")
            showFollowButton()
        case .following:
            print("Showing unfollow button")
            showUnfollowButton()
        }
    }
    
    private func setupActionButton(isUserProfile: Bool, followStatus: FollowStatus) {
        if isUserProfile {
            editProfileButton.isHidden = false
            editProfileButton.isEnabled = true
        } else {
            followUnfollowButton.isHidden = false
            followUnfollowButton.isEnabled = true
            switchFollowUnfollowButton(followStatus: followStatus)
        }
    }
    
    private func showFollowButton() {
        followUnfollowButton.setTitle("Follow", for: .normal)
        followUnfollowButton.backgroundColor = .systemBlue
        followUnfollowButton.setTitleColor(.white, for: .normal)
    }
    
    private func showUnfollowButton() {
        followUnfollowButton.setTitle("Unfollow", for: .normal)
        followUnfollowButton.backgroundColor = .systemBackground
        followUnfollowButton.setTitleColor(.label, for: .normal)
    }
    
    private func setupConstraints() {
        let followButtonBottomConstraint = followUnfollowButton.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor)
        followButtonBottomConstraint.priority = UILayoutPriority(999)
        let followButtonTrailingConstraint = followUnfollowButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15)
        followButtonTrailingConstraint.priority = UILayoutPriority(990)
        
        let editButtonBottomConstraint = editProfileButton.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor)
        editButtonBottomConstraint.priority = UILayoutPriority(999)
        let editButtonTrailingConstraint = editProfileButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15)
        editButtonTrailingConstraint.priority = UILayoutPriority(999)
        
        let followersButtonTrailingConstraint = followersButton.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -15)
        followersButtonTrailingConstraint.priority = UILayoutPriority(995)
        
        

        NSLayoutConstraint.activate([
            profilePhotoImageView.heightAnchor.constraint(equalToConstant: profilePhotoWidthHeight),
            profilePhotoImageView.widthAnchor.constraint(equalToConstant: profilePhotoWidthHeight),
            profilePhotoImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            profilePhotoImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),
            
            postsButton.topAnchor.constraint(equalTo: profilePhotoImageView.topAnchor),
            postsButton.leadingAnchor.constraint(equalTo: profilePhotoImageView.trailingAnchor, constant: 15),
            postsButton.widthAnchor.constraint(equalToConstant: 70),
            postsButton.heightAnchor.constraint(equalToConstant: 45),
            
            followingButton.topAnchor.constraint(equalTo: profilePhotoImageView.topAnchor),
            followingButton.leadingAnchor.constraint(equalTo: postsButton.trailingAnchor, constant: 10),
            followingButton.widthAnchor.constraint(equalToConstant: 70),
            followingButton.heightAnchor.constraint(equalToConstant: 45),
            
            followersButton.topAnchor.constraint(equalTo: profilePhotoImageView.topAnchor),
            followersButton.leadingAnchor.constraint(equalTo: followingButton.trailingAnchor, constant: 15),
            followersButtonTrailingConstraint,
            followersButton.widthAnchor.constraint(equalToConstant: 70),
            followersButton.heightAnchor.constraint(equalToConstant: 45),
            
            nameLabel.topAnchor.constraint(equalTo: profilePhotoImageView.bottomAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: profilePhotoImageView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: followersButton.trailingAnchor, constant: -15),
            nameLabel.heightAnchor.constraint(equalToConstant: 18),
            
            bioLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            bioLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            bioLabel.trailingAnchor.constraint(equalTo: followersButton.trailingAnchor),
            bioLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
            
            editProfileButton.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 15),
            editProfileButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),
            editButtonTrailingConstraint,
            editProfileButton.heightAnchor.constraint(equalToConstant: 30),
            editButtonBottomConstraint,

            followUnfollowButton.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 15),
            followUnfollowButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),
            followButtonTrailingConstraint,
            followUnfollowButton.heightAnchor.constraint(equalToConstant: 35),
            followButtonBottomConstraint,
        ])
    }
    
    @objc private func didTapPostsButton() {
        delegate?.postsButtonTapped(self)
    }
    @objc private func didTapFollowingButton() {
        delegate?.followingButtonTapped(self)
    }
    @objc private func didTapFollowersButton() {
        delegate?.followersButtonTapped(self)
    }
    @objc private func didTapEditProfileButton() {
        print("eddit button tapped")
        delegate?.editProfileButtonTapped(self)
    }
    @objc private func didTapFollowUnfollowButton() {
        switch followStatus {
            
        case .notFollowing:
            delegate?.followButtonTapped(self)
            
        case .following:
            delegate?.unfollowButtonTapped(self)
        }
    }
}

