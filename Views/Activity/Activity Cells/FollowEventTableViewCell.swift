//
//  FollowEventTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 22.01.2022.
//

import SDWebImage
import UIKit

protocol FollowEventTableViewCellDelegate: ActivityViewCellActionsDelegate, AnyObject {
    func followUserTapped(user: ZoogramUser, followCompletion: @escaping (FollowStatus) -> Void)
    func unfollowUserTapped(user: ZoogramUser, unfollowCompletion: @escaping (FollowStatus) -> Void)
}

class FollowEventTableViewCell: UITableViewCell {

    static let identifier = "FollowEventTableViewCell"

    weak var delegate: FollowEventTableViewCellDelegate?

    private var event: ActivityEvent?

    private let profileImageViewSize: CGFloat = 45

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()

    private let activityMessageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var followUnfollowButton: FollowUnfollowButton = {
        let button = FollowUnfollowButton()
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
        switchFollowUnfollowButton(followStatus: event.user?.followStatus)

        let attributedUsername = NSAttributedString(string: "\(event.user!.username) ", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.label])
        let attributedEventMessage = NSAttributedString(string: "started following you. ",
                                                        attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                                     .foregroundColor: UIColor.label])
        let attributedTimeStamp = NSAttributedString(string: event.date.timeAgoDisplay(),
                                                     attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                                  .foregroundColor: UIColor.secondaryLabel])

        let wholeMessage = NSMutableAttributedString()
        wholeMessage.append(attributedUsername)
        wholeMessage.append(attributedEventMessage)
        wholeMessage.append(attributedTimeStamp)

        // adding lineSpacing attribute
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        wholeMessage.addAttribute(NSAttributedString.Key.paragraphStyle,
                                  value: paragraphStyle,
                                  range: NSMakeRange(0, wholeMessage.length))

        activityMessageLabel.attributedText = wholeMessage

        let url = URL(string: event.user!.profilePhotoURL)
        profileImageView.sd_setImage(with: url, completed: nil)

        if event.seen == false {
            self.contentView.backgroundColor = ColorScheme.activityUnseenEventLightBlue
        } else {
            self.contentView.backgroundColor = .systemBackground
        }
    }

    private func setupViewsAndConstraints() {
        contentView.addSubviews(profileImageView, activityMessageLabel, followUnfollowButton)

        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            profileImageView.heightAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.widthAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

            activityMessageLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            activityMessageLabel.trailingAnchor.constraint(equalTo: followUnfollowButton.leadingAnchor, constant: -10),
            activityMessageLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 5),
            activityMessageLabel.bottomAnchor.constraint(lessThanOrEqualTo: profileImageView.bottomAnchor),

            followUnfollowButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            followUnfollowButton.centerYAnchor.constraint(equalTo: activityMessageLabel.centerYAnchor),
            followUnfollowButton.widthAnchor.constraint(equalToConstant: 80),
            followUnfollowButton.heightAnchor.constraint(equalToConstant: 30)
        ])

        profileImageView.layer.cornerRadius = profileImageViewSize / 2
    }

    private func switchFollowUnfollowButton(followStatus: FollowStatus?) {
        guard let followStatus = followStatus else {
            return
        }
        switch followStatus {
        case .notFollowing:
            followUnfollowButton.changeAppearenceToFollow()
        case .following:
            followUnfollowButton.changeAppearenceToUnfollow()
        }
    }

    @objc func didTapFollowUnfollowButton() {
        guard let user = event?.user else {
            return
        }

        switch user.followStatus {

        case .notFollowing:
            delegate?.followUserTapped(user: user) { followStatus in
                self.event?.user?.followStatus = followStatus
                self.switchFollowUnfollowButton(followStatus: followStatus)
            }

        case .following:
            delegate?.unfollowUserTapped(user: user) { followStatus in
                self.event?.user?.followStatus = followStatus
                self.switchFollowUnfollowButton(followStatus: followStatus)
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
