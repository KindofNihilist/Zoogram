//
//  PostCommentsTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 25.01.2022.
//

import UIKit
import SDWebImage

class PostCommentTableViewCell: UITableViewCell {
    
    static let identifier = "PostCommentsTableViewCell"
    
    private let profilePhotoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.text = "username"
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .label
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()
    
    private let timePassedLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.text = "2h"
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .systemBackground
        selectionStyle = .none
        setupViewsAndConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        profilePhotoImageView.layer.cornerRadius = 35 / 2
    }
    
    func configure(with viewModel: CommentViewModel) {
        messageLabel.text = viewModel.commentText
        messageLabel.sizeToFit()
        timePassedLabel.text = viewModel.datePostedText
        timePassedLabel.sizeToFit()
        usernameLabel.text = viewModel.author.username
        usernameLabel.sizeToFit()
        let url = URL(string: viewModel.author.profilePhotoURL)
        profilePhotoImageView.sd_setImage(with: url)
    }
    
    func configurePostCaption(caption: String, postAuthorUsername: String, postAuthorProfilePhoto: UIImage, timeSincePostedTitle: String) {
        messageLabel.text = caption
        messageLabel.sizeToFit()
        timePassedLabel.text = timeSincePostedTitle
        timePassedLabel.sizeToFit()
        usernameLabel.text = postAuthorUsername
        usernameLabel.sizeToFit()
        profilePhotoImageView.image = postAuthorProfilePhoto
    }
    
    private func setupViewsAndConstraints() {
        contentView.addSubviews(profilePhotoImageView, usernameLabel, messageLabel, timePassedLabel)
        
        NSLayoutConstraint.activate([
            profilePhotoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            profilePhotoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            profilePhotoImageView.heightAnchor.constraint(equalToConstant: 35),
            profilePhotoImageView.widthAnchor.constraint(equalToConstant: 35),
            
            usernameLabel.topAnchor.constraint(equalTo: profilePhotoImageView.topAnchor),
            usernameLabel.leadingAnchor.constraint(equalTo: profilePhotoImageView.trailingAnchor, constant: 10),
            
            messageLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 5),
            messageLabel.leadingAnchor.constraint(equalTo: profilePhotoImageView.trailingAnchor, constant: 10),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -30),
            
            timePassedLabel.leadingAnchor.constraint(equalTo: messageLabel.leadingAnchor),
            timePassedLabel.topAnchor.constraint(equalTo:  messageLabel.bottomAnchor, constant: 5),
            timePassedLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)
        ])
    }
}

