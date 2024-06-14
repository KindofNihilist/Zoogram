//
//  FollowEventTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 22.01.2022.
//

import SDWebImage
import UIKit

@MainActor protocol FollowEventTableViewCellDelegate: ActivityViewCellActionsDelegate, AnyObject {
    func followUserTapped(user: ZoogramUser, followCompletion: @escaping (FollowStatus) -> Void)
    func unfollowUserTapped(user: ZoogramUser, unfollowCompletion: @escaping (FollowStatus) -> Void)
}

class FollowEventTableViewCell: UITableViewCell {

    static let identifier = "FollowEventTableViewCell"

    weak var delegate: FollowEventTableViewCellDelegate?

    private var event: ActivityEvent?

    private let profileImageViewSize: CGFloat = 45

    private let profileImageView: ProfilePictureImageView = {
        let imageView = ProfilePictureImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let activityMessageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var followUnfollowButton: FollowUnfollowButton = {
        let button = FollowUnfollowButton(followStatus: .notFollowing)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapFollowUnfollowButton), for: .touchUpInside)
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupViewsAndConstraints()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapUserProfile))
        self.addGestureRecognizer(tapGestureRecognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(with event: ActivityEvent) {
        self.event = event
        if let followStatus = event.user?.followStatus {
            self.followUnfollowButton.followStatus = followStatus
        }
        let attributedUsername = NSAttributedString(
            string: "\(event.user!.username) ",
            attributes: [.font: CustomFonts.boldFont(ofSize: 14), .foregroundColor: Colors.label])
        let localizedMessage = String(localized: "started following you. ")
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
        wholeMessage.addAttribute(NSAttributedString.Key.paragraphStyle,
                                  value: paragraphStyle,
                                  range: NSRange(location: 0, length: wholeMessage.length))

        activityMessageLabel.attributedText = wholeMessage

        profileImageView.image = event.user?.getProfilePhoto() ?? UIImage.profilePicturePlaceholder

        if event.seen == false {
            self.contentView.backgroundColor = Colors.unseenBlue
        } else {
            self.contentView.backgroundColor = Colors.background
        }
    }

    private func setupViewsAndConstraints() {
        contentView.addSubviews(profileImageView, activityMessageLabel, followUnfollowButton)

        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            profileImageView.heightAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.widthAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),

            activityMessageLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            activityMessageLabel.trailingAnchor.constraint(lessThanOrEqualTo: followUnfollowButton.leadingAnchor, constant: -10),
            activityMessageLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 2),
            activityMessageLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -10),

            followUnfollowButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            followUnfollowButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            followUnfollowButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 90),
            followUnfollowButton.heightAnchor.constraint(equalToConstant: 30)
        ])

        profileImageView.layer.cornerRadius = profileImageViewSize / 2
    }

    @objc func didTapFollowUnfollowButton() {
        guard let user = event?.user else {
            return
        }

        switch user.followStatus {

        case .notFollowing:
            delegate?.followUserTapped(user: user) { followStatus in
                self.event?.user?.followStatus = followStatus
                self.followUnfollowButton.followStatus = followStatus
            }

        case .following:
            delegate?.unfollowUserTapped(user: user) { followStatus in
                self.event?.user?.followStatus = followStatus
                self.followUnfollowButton.followStatus = followStatus
            }
        case .none: return
        }
    }

    @objc func didTapUserProfile() {
        guard let user = self.event?.user else {
            return
        }
        delegate?.didSelectUser(user: user)
    }
}
