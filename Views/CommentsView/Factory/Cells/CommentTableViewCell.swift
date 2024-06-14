//
//  PostCommentsTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 25.01.2022.
//

import UIKit
import SDWebImage

@MainActor protocol CommentCellProtocol: AnyObject {
    func openUserProfile(of commentAuthor: ZoogramUser)
}

class CommentTableViewCell: UITableViewCell {

    weak var delegate: CommentCellProtocol?

    private var author: ZoogramUser!

    private let profilePhotoImageView: ProfilePictureImageView = {
        let imageView = ProfilePictureImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = CustomFonts.boldFont(ofSize: 14)
        label.isUserInteractionEnabled = true
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Colors.label
        label.font = CustomFonts.regularFont(ofSize: 14)
        label.numberOfLines = 0
        label.sizeToFit()
        return label
    }()

    private let timePassedLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = CustomFonts.regularFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = Colors.background
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
        profilePhotoImageView.layer.cornerRadius = 40 / 2
    }

    func configure(with comment: PostComment) {
        author = comment.author
        messageLabel.attributedText = comment.commentText.lineWithSpacing(2)
        timePassedLabel.text = comment.datePosted.timeAgoDisplay()
        usernameLabel.text = comment.author.username
        profilePhotoImageView.image = comment.author.getProfilePhoto() ?? UIImage.profilePicturePlaceholder
        if comment.shouldBeMarkedUnseen {
            backgroundColor = Colors.unseenBlue
        }
    }

    func configurePostCaption(with comment: PostComment) {
        author = comment.author
        messageLabel.text = comment.commentText
        timePassedLabel.text = comment.datePosted.timeAgoDisplay()
        usernameLabel.text = comment.author.username
        profilePhotoImageView.image = comment.author.getProfilePhoto() ?? UIImage.profilePicturePlaceholder
    }

    private func setupViewsAndConstraints() {
        contentView.addSubviews(profilePhotoImageView, usernameLabel, messageLabel, timePassedLabel)

        NSLayoutConstraint.activate([
            profilePhotoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            profilePhotoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            profilePhotoImageView.heightAnchor.constraint(equalToConstant: 40),
            profilePhotoImageView.widthAnchor.constraint(equalToConstant: 40),

            usernameLabel.topAnchor.constraint(equalTo: profilePhotoImageView.topAnchor),
            usernameLabel.leadingAnchor.constraint(equalTo: profilePhotoImageView.trailingAnchor, constant: 10),

            messageLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: profilePhotoImageView.trailingAnchor, constant: 10),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -30),

            timePassedLabel.leadingAnchor.constraint(equalTo: messageLabel.leadingAnchor),
            timePassedLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 5),
            timePassedLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)
        ])
    }

    @objc func openUserProfile() {
        delegate?.openUserProfile(of: self.author)
    }
}
