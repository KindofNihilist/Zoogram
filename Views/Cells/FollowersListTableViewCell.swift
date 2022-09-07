//
//  FollowersListTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 21.01.2022.
//

import UIKit

protocol FollowersListTableViewCellDelegate: AnyObject {
    func didTapRemoveButton(model: String)
}

class FollowersListTableViewCell: UITableViewCell {
    
    static let identifier = "FollowersListTableViewCell"
    
    weak var delegate: FollowersListTableViewCellDelegate?
    
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
    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        profileImageView.image = nil
//        usernameLabel.text = nil
//        nameLabel.text = nil
//        removeButton.setTitle(nil, for: .normal)
//    }
    
    private func showFollowButton() {
        followUnfollowButton.setTitle("Follow", for: .normal)
        followUnfollowButton.setTitleColor(.systemBlue, for: .normal)
    }
    
    
    private func showUnfollowButton() {
        followUnfollowButton.setTitle("Unfollow", for: .normal)
        followUnfollowButton.setTitleColor(.label, for: .normal)
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
    }
}


