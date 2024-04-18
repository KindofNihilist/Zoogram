//
//  PostLikedTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 22.01.2022.
//
import SDWebImage
import UIKit

class PostLikedEventTableViewCell: UITableViewCell {

    static let identifier = "PostLikedEventTableViewCell"

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

    private let likedPostPhotoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .secondaryLabel
        imageView.layer.masksToBounds = true
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        let userProfileGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didSelectUser))
        let userProfileImageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didSelectUser))
        profileImageView.addGestureRecognizer(userProfileImageGestureRecognizer)
        activityMessageLabel.addGestureRecognizer(userProfileGestureRecognizer)
        setupViewsAndConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(with event: ActivityEvent) {
        self.event = event
        likedPostPhotoImageView.image = event.post?.image

        let attributedUsername = NSAttributedString(string: "\(event.user!.username) ", attributes: [NSAttributedString.Key.font: CustomFonts.boldFont(ofSize: 14), NSAttributedString.Key.foregroundColor: Colors.label])
        let localizedMessage = String(localized: "liked your post. ")
        let attributedEventMessage = NSAttributedString(
            string: localizedMessage,
            attributes: [.font: CustomFonts.regularFont(ofSize: 14), .foregroundColor: Colors.label])

        let attributedTimeStamp = NSAttributedString(
            string: event.date.timeAgoDisplay(),
            attributes: [.font: CustomFonts.regularFont(ofSize: 14), .foregroundColor: UIColor.secondaryLabel])

        let wholeMessage = NSMutableAttributedString()
        wholeMessage.append(attributedUsername)
        wholeMessage.append(attributedEventMessage)
        wholeMessage.append(attributedTimeStamp)

        // adding lineSpacing attribute
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakStrategy = .pushOut
        paragraphStyle.lineSpacing = 2
        wholeMessage.addAttribute(.paragraphStyle,
                                  value: paragraphStyle,
                                  range: NSMakeRange(0, wholeMessage.length))

        profileImageView.image = event.user?.getProfilePhoto()

        activityMessageLabel.attributedText = wholeMessage

        if event.seen == false {
            self.contentView.backgroundColor = Colors.unseenBlue
        } else {
            self.contentView.backgroundColor = Colors.background
        }
    }

    private func setupViewsAndConstraints() {
        contentView.addSubviews(profileImageView, activityMessageLabel, likedPostPhotoImageView)

        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            profileImageView.heightAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.widthAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),

            activityMessageLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            activityMessageLabel.trailingAnchor.constraint(equalTo: likedPostPhotoImageView.leadingAnchor, constant: -10),
            activityMessageLabel.topAnchor.constraint(equalTo: likedPostPhotoImageView.topAnchor, constant: 2),
            activityMessageLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),

            likedPostPhotoImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            likedPostPhotoImageView.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            likedPostPhotoImageView.widthAnchor.constraint(equalToConstant: profileImageViewSize),
            likedPostPhotoImageView.heightAnchor.constraint(equalToConstant: profileImageViewSize)
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
