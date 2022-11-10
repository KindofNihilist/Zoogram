//
//  FollowersListTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 21.01.2022.
//

import UIKit

protocol FollowListCellDelegate: AnyObject {
    func removeButtonTapped(userID: String, removeCompletion: @escaping (FollowStatus) -> Void)
    func undoButtonTapped(userID: String, undoCompletion: @escaping (FollowStatus) -> Void)
    func followButtonTapped(userID: String, followCompletion: @escaping (FollowStatus) -> Void)
    func unfollowButtonTapped(userID: String, unfollowCompletion: @escaping (FollowStatus) -> Void)
}

class FollowersListTableViewCell: UITableViewCell {
    
    static let identifier = "FollowersListTableViewCell"
    
    private var followStatus: FollowStatus!
    
    private var isFollowingMe: FollowStatus = .following
    
    private var userID: String!
    
    weak var delegate: FollowListCellDelegate?
    
    private let profileImageViewSize: CGFloat = 55
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        //        label.text = "Пухляш220_🐈"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        //        label.text = "Пухляш :3"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        return label
    }()
    
    private let removeButton: UIButton = {
        let button = UIButton()
        button.setTitle("Remove", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.backgroundColor = .systemBackground
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(removeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let followUnfollowButton: UIButton = {
        let button = UIButton()
        button.setTitle("Follow", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapFollowUnfollowButton), for: .touchUpInside)
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
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            profileImageView.heightAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.widthAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            removeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            removeButton.heightAnchor.constraint(equalToConstant: 30),
            removeButton.widthAnchor.constraint(equalToConstant: 65),
            removeButton.topAnchor.constraint(equalTo: usernameLabel.topAnchor),
            
            usernameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            usernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: followUnfollowButton.leadingAnchor),
            usernameLabel.heightAnchor.constraint(equalToConstant: 15),
            usernameLabel.bottomAnchor.constraint(equalTo: profileImageView.centerYAnchor, constant: -5),
            
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            nameLabel.trailingAnchor.constraint(equalTo: usernameLabel.trailingAnchor),
            nameLabel.heightAnchor.constraint(equalToConstant: 15),
            nameLabel.topAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            
            followUnfollowButton.leadingAnchor.constraint(equalTo: usernameLabel.trailingAnchor, constant: 5),
            followUnfollowButton.trailingAnchor.constraint(lessThanOrEqualTo: removeButton.leadingAnchor, constant: -15),
            followUnfollowButton.heightAnchor.constraint(equalToConstant: 15),
            followUnfollowButton.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor),
        ])
        
        profileImageView.layer.cornerRadius = profileImageViewSize / 2
    }
    
    func configure(userID: String, followStatus: FollowStatus) {
        self.followStatus = followStatus
        self.userID = userID
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
            removeButton.setTitle("Remove", for: .normal)
        case .notFollowing:
            removeButton.setTitle("Undo", for: .normal)
        }
    }
    
    private func showFollowButton() {
        followUnfollowButton.setTitle("Follow", for: .normal)
        followUnfollowButton.setTitleColor(.systemBlue, for: .normal)
    }
    
    
    private func showUnfollowButton() {
        followUnfollowButton.setTitle("Unfollow", for: .normal)
        followUnfollowButton.setTitleColor(.label, for: .normal)
    }
    
    @objc func removeButtonTapped() {
        switch isFollowingMe {
        case .following:
            delegate?.removeButtonTapped(userID: userID) { status in
                self.switchRemoveButton(followStatus: status)
                self.isFollowingMe = .notFollowing
            }
        case .notFollowing:
            delegate?.undoButtonTapped(userID: userID) { status in
                self.switchRemoveButton(followStatus: status)
                self.isFollowingMe = .following
            }
        }
        
    }
    
    @objc func didTapFollowUnfollowButton() {
        
        switch followStatus {
            
        case .notFollowing:
            delegate?.followButtonTapped(userID: self.userID) { status in
                self.followStatus = status
                self.switchFollowUnfollowButton(followStatus: status)
            }
        case .following:
            delegate?.unfollowButtonTapped(userID: self.userID) { status in
                self.followStatus = status
                self.switchFollowUnfollowButton(followStatus: status)
            }
        default:
            print("Follow status isn't set")
        }
    }
}

