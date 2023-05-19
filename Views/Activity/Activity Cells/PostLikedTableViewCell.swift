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

    var userProfileGestureRecognizer = UITapGestureRecognizer()
//    var postGestureRecognizer = UITapGestureRecognizer()

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .secondarySystemBackground
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private let activityMessageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
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
        self.userProfileGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didSelectUser))
//        self.postGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didSelectPost))
        setupViewsAndConstraints()
        profileImageView.addGestureRecognizer(userProfileGestureRecognizer)
//        likedPostPhotoImageView.addGestureRecognizer(postGestureRecognizer)
//        self.addGestureRecognizer(postGestureRecognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(with event: ActivityEvent) {
        self.event = event
        likedPostPhotoImageView.image = event.post?.image

        let attributedUsername = NSAttributedString(string: "\(event.user!.username) ", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.label])
        let attributedEventMessage = NSAttributedString(string: "liked your post. ",
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
        wholeMessage.addAttribute(.paragraphStyle,
                                  value: paragraphStyle,
                                  range: NSMakeRange(0, wholeMessage.length))

        let url = URL(string: event.user!.profilePhotoURL)
        profileImageView.sd_setImage(with: url, completed: nil)

        activityMessageLabel.attributedText = wholeMessage

        if event.seen == false {
            self.contentView.backgroundColor = ColorScheme.activityUnseenEventLightBlue
        } else {
            self.contentView.backgroundColor = .systemBackground
        }
    }

    private func setupViewsAndConstraints() {
        contentView.addSubviews(profileImageView, activityMessageLabel, likedPostPhotoImageView)

        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            profileImageView.heightAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.widthAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

            activityMessageLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            activityMessageLabel.trailingAnchor.constraint(equalTo: likedPostPhotoImageView.leadingAnchor, constant: -10),
            activityMessageLabel.topAnchor.constraint(equalTo: likedPostPhotoImageView.topAnchor, constant: 5),
            activityMessageLabel.bottomAnchor.constraint(lessThanOrEqualTo: likedPostPhotoImageView.bottomAnchor),

            likedPostPhotoImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            likedPostPhotoImageView.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            likedPostPhotoImageView.widthAnchor.constraint(equalToConstant: profileImageViewSize),
            likedPostPhotoImageView.heightAnchor.constraint(equalToConstant: profileImageViewSize)
        ])

        profileImageView.layer.cornerRadius = profileImageViewSize / 2
    }

    @objc func didSelectUser() {
        print("Did select user")
        guard let user = event?.user else {
            return
        }
        delegate?.didSelectUser(user: user)
    }
}
