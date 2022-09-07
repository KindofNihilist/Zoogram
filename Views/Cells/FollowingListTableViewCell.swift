//
//  FollowingListTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 21.01.2022.
//

import UIKit

protocol FollowingListTableViewCellDelegate: AnyObject {
    func didTapFollowUnfollowButton(model: UserRelationship)
}

class FollowingListTableViewCell: UITableViewCell {
    
    static let identifier = "FollowingListTableViewCell"
    
    weak var delegate: FollowingListTableViewCellDelegate?
    
    private var model: UserRelationship?
    
    private let profileImageViewSize: CGFloat = 55
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
//        label.text = "Пухляш220_🐈"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
//        label.text = "Пухляш :3"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        return label
    }()
    
    private let followUnfollowButton: UIButton = {
        let button = UIButton()
        button.setTitle("Unfollow", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.backgroundColor = .systemBackground
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.cornerRadius = 5
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
        contentView.addSubviews(profileImageView, followUnfollowButton, usernameLabel, nameLabel)
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            profileImageView.heightAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.widthAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            followUnfollowButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            followUnfollowButton.heightAnchor.constraint(equalToConstant: 30),
            followUnfollowButton.widthAnchor.constraint(equalToConstant: 80),
            followUnfollowButton.topAnchor.constraint(equalTo: usernameLabel.topAnchor),
            
            usernameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            usernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: followUnfollowButton.leadingAnchor),
            usernameLabel.heightAnchor.constraint(equalToConstant: 15),
            usernameLabel.bottomAnchor.constraint(equalTo: profileImageView.centerYAnchor, constant: -5),
            
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            nameLabel.trailingAnchor.constraint(equalTo: usernameLabel.trailingAnchor),
            nameLabel.heightAnchor.constraint(equalToConstant: 15),
            nameLabel.topAnchor.constraint(equalTo: profileImageView.centerYAnchor),
        ])
        
        profileImageView.layer.cornerRadius = profileImageViewSize / 2
    }
    
    
    public func configure(with model: UserRelationship) {
        self.model = model
        usernameLabel.text = model.username
        nameLabel.text = model.name
        switch model.type {
        case .following:
            showUnfollowButton()
        case .notFollowing:
            showFollowButton()
        }
    }
    
    
    private func showFollowButton() {
        followUnfollowButton.setTitle("Follow", for: .normal)
        followUnfollowButton.backgroundColor = .systemBlue
        followUnfollowButton.setTitleColor(.white, for: .normal)
        followUnfollowButton.layer.borderWidth = 0
        followUnfollowButton.layer.borderColor = .none
    }
    
    
    private func showUnfollowButton() {
        followUnfollowButton.setTitle("Unfollow", for: .normal)
        followUnfollowButton.backgroundColor = .systemBackground
        followUnfollowButton.setTitleColor(.label, for: .normal)
        followUnfollowButton.layer.borderWidth = 0.5
        followUnfollowButton.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    @objc func didTapFollowUnfollowButton() {
        guard let model = model else {
            return 
        }
        switch model.type {
        case .following:
            showUnfollowButton()
        case .notFollowing:
            showFollowButton()
        }
        delegate?.didTapFollowUnfollowButton(model: model)
    }
    
    
}

 
