//
//  PostCommentsTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 25.01.2022.
//

import UIKit
import SDWebImage

protocol CommentCellProtocol: AnyObject {
    func openUserProfile(of commentAuthor: ZoogramUser)
}

class CommentTableViewCell: UITableViewCell {

    weak var delegate: CommentCellProtocol?

    private var author: ZoogramUser!

    private let profilePhotoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .secondarySystemBackground
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.text = "username"
        label.isUserInteractionEnabled = true
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
        let usernameGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openUserProfile))
        let profileImageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openUserProfile))
        self.usernameLabel.addGestureRecognizer(usernameGestureRecognizer)
        self.profilePhotoImageView.addGestureRecognizer(profileImageGestureRecognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        profilePhotoImageView.layer.cornerRadius = 35 / 2
    }

    func configure(with viewModel: CommentViewModel) {
        author = viewModel.author
        messageLabel.text = viewModel.commentText
        messageLabel.sizeToFit()
        timePassedLabel.text = viewModel.datePostedText
        timePassedLabel.sizeToFit()
        usernameLabel.text = viewModel.author.username
        usernameLabel.sizeToFit()
        profilePhotoImageView.image = viewModel.author.profilePhoto
    }

    func configurePostCaption(with viewModel: CommentViewModel) {
        messageLabel.text = viewModel.commentText
        messageLabel.sizeToFit()
        timePassedLabel.text = viewModel.datePostedText
        timePassedLabel.sizeToFit()
        usernameLabel.text = viewModel.author.username
        usernameLabel.sizeToFit()
        profilePhotoImageView.image = viewModel.author.profilePhoto
    }

    private func setupViewsAndConstraints() {
        contentView.addSubviews(profilePhotoImageView, usernameLabel, messageLabel, timePassedLabel)

        NSLayoutConstraint.activate([
            profilePhotoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            profilePhotoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
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

    @objc func openUserProfile() {
        delegate?.openUserProfile(of: self.author)
    }
}
