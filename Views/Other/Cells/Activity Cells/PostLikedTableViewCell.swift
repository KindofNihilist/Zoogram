//
//  PostLikedTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 22.01.2022.
//
import SDWebImage
import UIKit

protocol PostLikedTableViewCellDelegate: AnyObject {
    func didTapRelatedPost(model: UserActivity)
}

class PostLikedTableViewCell: UITableViewCell {
    
    static let identifier = "PostLikedTableViewCell"
    
    weak var delegate: PostLikedTableViewCellDelegate?
    
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
    
    private let likedPostPhotoImageView: UIImageView = {
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(with model: UserActivity) {
        self.model = model
        switch model.type {
        case .liked(let post):
            likedPostPhotoImageView.sd_setImage(with: URL(string: post.photoURL), completed: nil)
        case .followed:
            break
        case .commented:
            break
        }
        
        let attributedUsername = NSAttributedString(string: "\(model.user.username) ", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.label])
        let attributedEventMessage = NSAttributedString(string: "liked your post. ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.label])
        let attributedTimeStamp = NSAttributedString(string: "2h", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        
        let wholeMessage = NSMutableAttributedString()
        wholeMessage.append(attributedUsername)
        wholeMessage.append(attributedEventMessage)
        wholeMessage.append(attributedTimeStamp)
        
        // adding lineSpacing attribute
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        wholeMessage.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, wholeMessage.length))
    
        profileImageView.sd_setImage(with: URL(string: model.user.profilePhotoURL), completed: nil)
        
        activityMessageLabel.attributedText = wholeMessage
        
        
        
    }
    
    private func setupViewsAndConstraints() {
        contentView.addSubviews(profileImageView, activityMessageLabel, likedPostPhotoImageView)
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            profileImageView.heightAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.widthAnchor.constraint(equalToConstant: profileImageViewSize),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            activityMessageLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            activityMessageLabel.trailingAnchor.constraint(equalTo: likedPostPhotoImageView.leadingAnchor, constant: -5),
            activityMessageLabel.topAnchor.constraint(equalTo: likedPostPhotoImageView.topAnchor, constant: 5),
            activityMessageLabel.bottomAnchor.constraint(lessThanOrEqualTo: likedPostPhotoImageView.bottomAnchor),
            
            likedPostPhotoImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            likedPostPhotoImageView.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            likedPostPhotoImageView.widthAnchor.constraint(equalToConstant: profileImageViewSize),
            likedPostPhotoImageView.heightAnchor.constraint(equalToConstant: profileImageViewSize),
        ])
        
        profileImageView.layer.cornerRadius = profileImageViewSize / 2
    }
    
}
