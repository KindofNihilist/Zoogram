//
//  PostCommentedTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.02.2023.
//

import UIKit

//
//  PostLikedTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 22.01.2022.
//
import SDWebImage
import UIKit

class PostCommentedEventTableViewCell: UITableViewCell {
    
    static let identifier = "PostCommentedTableViewCell"
    
    weak var delegate: ActivityViewCellActionsDelegate?
    
    var userProfileGestureRecognizer = UITapGestureRecognizer()
    var postGestureRecognizer = UITapGestureRecognizer()
    
    private var event: ActivityEvent?
    
    private let profileImageViewSize: CGFloat = 45
    
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
        setupViewsAndConstraints()
        self.userProfileGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didSelectUser))
        self.postGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didSelectRelatedPost))
        profileImageView.addGestureRecognizer(userProfileGestureRecognizer)
        self.addGestureRecognizer(postGestureRecognizer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with event: ActivityEvent) {
        guard let comment = event.text else {
            return
        }
        self.event = event
        postPhotoImageView.sd_setImage(with: URL(string: event.post!.photoURL), completed: nil)
        
        let attributedUsername = NSAttributedString(string: "\(event.user!.username) ", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.label])
        let attributedEventMessage = NSAttributedString(string: "commented: \n\(comment) ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.label])
        let attributedTimeStamp = NSAttributedString(string: event.date.timeAgoDisplay(), attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        
        let wholeMessage = NSMutableAttributedString()
        wholeMessage.append(attributedUsername)
        wholeMessage.append(attributedEventMessage)
        wholeMessage.append(attributedTimeStamp)
        
        // adding lineSpacing attribute
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1
        wholeMessage.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, wholeMessage.length))
        
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
        contentView.addSubviews(profileImageView, activityMessageLabel, postPhotoImageView)
        
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            profileImageView.heightAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.widthAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            activityMessageLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            activityMessageLabel.trailingAnchor.constraint(equalTo: postPhotoImageView.leadingAnchor, constant: -10),
            activityMessageLabel.topAnchor.constraint(equalTo: postPhotoImageView.topAnchor, constant: 5),
            activityMessageLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),
            
            postPhotoImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            postPhotoImageView.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            postPhotoImageView.widthAnchor.constraint(equalToConstant: profileImageViewSize),
            postPhotoImageView.heightAnchor.constraint(equalToConstant: profileImageViewSize),
        ])
        
        profileImageView.layer.cornerRadius = profileImageViewSize / 2
    }
    
    @objc func didSelectUser() {
        print("did select user")
        guard let user = event?.user else {
            return
        }
        print("inside guard did select user")
        delegate?.didSelectUser(user: user)
    }
    
    @objc func didSelectRelatedPost() {
        print("did select post")
        guard let post = event?.post,
              let photo = postPhotoImageView.image,
              let commentID = event?.commentID
        else {
            return
        }
        print("inside guard did select post")
        delegate?.didSelectRelatedPost(post: post, postPhoto: photo, shouldFocusOnComment: true, commentID: commentID)
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.postGestureRecognizer && otherGestureRecognizer == self.userProfileGestureRecognizer {
            return true
        } else {
            return false
        }
    }
    
    
}

