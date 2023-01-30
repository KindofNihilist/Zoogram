//
//  FollowEventTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 22.01.2022.
//

import SDWebImage
import UIKit

protocol FollowEventTableViewCellDelegate: AnyObject {
    func didTapFollowUnfollowButton(model: UserActivity)
}

class FollowEventTableViewCell: UITableViewCell {
    
    static let identifier = "FollowEventTableViewCell"
    
    weak var delegate: FollowEventTableViewCellDelegate?
    
    private var model: UserActivity?
    
    private let profileImageViewSize: CGFloat = 55
    
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(with model: UserActivity) {
        self.model = model
        switch model.type {
        case .liked(_):
//            likedPostPhotoImageView.sd_setImage(with: post.thumbnailImage, completed: nil)
            break
        case .followed(let state):
            switch state {
            case .following:
                showUnfollowButton()
            case .notFollowing:
                showFollowButton()
            }
            break
        case .commented:
            break
        }
        
        let attributedUsername = NSAttributedString(string: "\(model.user.username) ", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.label])
        let attributedEventMessage = NSAttributedString(string: "started following you. ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.label])
        let attributedTimeStamp = NSAttributedString(string: "10h", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        
        let wholeMessage = NSMutableAttributedString()
        wholeMessage.append(attributedUsername)
        wholeMessage.append(attributedEventMessage)
        wholeMessage.append(attributedTimeStamp)
        
        // adding lineSpacing attribute
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        wholeMessage.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, wholeMessage.length))
        
        activityMessageLabel.attributedText = wholeMessage
        profileImageView.sd_setImage(with: URL(string: model.user.profilePhotoURL), completed: nil)
        
    }
    
    private func setupViewsAndConstraints() {
        contentView.addSubviews(profileImageView, activityMessageLabel, followUnfollowButton)
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            profileImageView.heightAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.widthAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            activityMessageLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            activityMessageLabel.trailingAnchor.constraint(equalTo: followUnfollowButton.leadingAnchor, constant: -5),
            activityMessageLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 5),
            activityMessageLabel.bottomAnchor.constraint(lessThanOrEqualTo: profileImageView.bottomAnchor),
            
            followUnfollowButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            followUnfollowButton.centerYAnchor.constraint(equalTo: activityMessageLabel.centerYAnchor),
            followUnfollowButton.widthAnchor.constraint(equalToConstant: 80),
            followUnfollowButton.heightAnchor.constraint(equalToConstant: 30),
        ])
        
        profileImageView.layer.cornerRadius = profileImageViewSize / 2
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
        delegate?.didTapFollowUnfollowButton(model: model)
    }
    
}

