//
//  PostCommentedTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.02.2023.
//

import SDWebImage
import UIKit

class PostCommentedEventTableViewCell: UITableViewCell {

    static let identifier = "PostCommentedTableViewCell"

    weak var delegate: ActivityViewCellActionsDelegate?

    private var event: ActivityEvent?

    private let profileImageViewSize: CGFloat = 45

    private let profileImageView: ProfilePictureImageView = {
        let imageView = ProfilePictureImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private let activityMessageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        return label
    }()

    private let postPhotoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .secondaryLabel
        imageView.layer.masksToBounds = true
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupViewsAndConstraints()
        let userProfileImageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didSelectUser))
        profileImageView.addGestureRecognizer(userProfileImageGestureRecognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with event: ActivityEvent) {
        self.event = event
        self.postPhotoImageView.image = event.post?.image
        let attributedString = createAttributedString(for: event)
        profileImageView.image = event.user?.getProfilePhoto() ?? UIImage.profilePicturePlaceholder
        activityMessageLabel.attributedText = attributedString
        if event.seen == false {
            self.contentView.backgroundColor = Colors.unseenBlue
        } else {
            self.contentView.backgroundColor = Colors.background
        }
    }

    private func createAttributedString(for event: ActivityEvent) -> NSAttributedString {
        guard let comment = event.text else {
            return NSAttributedString()
        }
        let attributedUsername = NSAttributedString(
            string: "\(event.user!.username) ",
            attributes: [.font: CustomFonts.boldFont(ofSize: 14),
                         .foregroundColor: Colors.label])
        let localizedMessage = String(localized: "commented: \n\(comment) ")
        let attributedEventMessage = NSAttributedString(
            string: localizedMessage,
            attributes: [.font: CustomFonts.regularFont(ofSize: 14),
                         .foregroundColor: Colors.label])
        let attributedTimeStamp = NSAttributedString(
            string: event.timestamp.timeAgoDisplay(),
            attributes: [.font: CustomFonts.regularFont(ofSize: 14),
                         .foregroundColor: UIColor.secondaryLabel])

        let wholeMessage = NSMutableAttributedString()
        wholeMessage.append(attributedUsername)
        wholeMessage.append(attributedEventMessage)
        wholeMessage.append(attributedTimeStamp)

        // adding lineSpacing attribute
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.lineBreakStrategy = .pushOut
        wholeMessage.addAttribute(.paragraphStyle,
                                  value: paragraphStyle,
                                  range: NSRange(location: 0, length: wholeMessage.length))
        return wholeMessage
    }

    private func setupViewsAndConstraints() {
        contentView.addSubviews(profileImageView, activityMessageLabel, postPhotoImageView)

        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            profileImageView.heightAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.widthAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),

            activityMessageLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            activityMessageLabel.trailingAnchor.constraint(equalTo: postPhotoImageView.leadingAnchor, constant: -10),
            activityMessageLabel.topAnchor.constraint(equalTo: postPhotoImageView.topAnchor, constant: 2),
            activityMessageLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),

            postPhotoImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            postPhotoImageView.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            postPhotoImageView.widthAnchor.constraint(equalToConstant: profileImageViewSize),
            postPhotoImageView.heightAnchor.constraint(equalToConstant: profileImageViewSize)
        ])

        profileImageView.layer.cornerRadius = profileImageViewSize / 2
    }

    @objc func didSelectUser() {
        guard let user = event?.user else {
            return
        }
        delegate?.didSelectUser(user: user)
    }
}
