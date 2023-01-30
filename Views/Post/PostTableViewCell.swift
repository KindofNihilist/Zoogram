//
//  PostTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 20.01.2023.
//

import UIKit
import SDWebImage

protocol PostTableViewCellProtocol: AnyObject {
    func menuButtonTapped(forPost: String, atIndex: Int)
    func didSelectUser(userID: String, atIndex: Int)
    func didTapLikeButton(postID: String, postActionsCell: PostTableViewCell)
    func didTapCommentButton(post: UserPost)
}

class PostTableViewCell: UITableViewCell {
    
    static let identifier = "PostTableViewCell"
    
    var delegate: PostTableViewCellProtocol?
    var likeButtonState: PostLikeState?
    var index: Int?
    var post: UserPost?
    
    var imageViewHeightConstraint: NSLayoutConstraint!
    
//    override func prepareForReuse() {
//        removeConstraints(postImageView.constraints)
//    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        clipsToBounds = true
        setupHeader()
        setupContentView()
        setupActionsView()
        setupFooter()
        addGestureRecognizers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK: Post Header
    
    private let headerContainerView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()

    private let profilePhotoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()
    
    private let usernameLabel: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .label
        return label
    }()
    
    private let menuButton: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 19)), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: #selector(menuButtonTapped), for: .touchUpInside)
        return button
    }()
    
    //MARK: Post Content View
    
    let postImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .secondarySystemBackground
        imageView.clipsToBounds = true
        return imageView
    }()
    
    //MARK: Post Actions
    
    private let actionsContainerView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()
    
    private let likeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "heart", withConfiguration: UIImage.SymbolConfiguration(pointSize: 29)), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .label
        button.backgroundColor = .systemBackground
        button.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let commentButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "bubble.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 29)), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .label
        button.backgroundColor = .systemBackground
        button.addTarget(self, action: #selector(commentButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let bookmarkButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "bookmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 29)), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .label
        return button
    }()
    
    //MARK: Post Comments
    private let commentsContainerView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()
    
    private let commenterProfilePhotoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .label
        label.font = UIFont.systemFont(ofSize: 13)
        label.text = "Wow what a cool post!"
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
    
    //MARK: Post Footer
    
    private let footerContainerView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()
    
    private let likesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var captionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var viewCommentsButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    private let timeSincePostedLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()
    
    //MARK: Constraints setup
    
    func setupHeader() {
        contentView.addSubview(headerContainerView)
        headerContainerView.addSubviews(profilePhotoImageView, usernameLabel, menuButton)
        profilePhotoImageView.layer.cornerRadius = 35 / 2
        
        NSLayoutConstraint.activate([
            headerContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerContainerView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        NSLayoutConstraint.activate([
            profilePhotoImageView.centerYAnchor.constraint(equalTo: headerContainerView.centerYAnchor),
            profilePhotoImageView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor, constant: 10),
            profilePhotoImageView.heightAnchor.constraint(equalToConstant: 35),
            profilePhotoImageView.widthAnchor.constraint(equalToConstant: 35),
            
            usernameLabel.centerYAnchor.constraint(equalTo: headerContainerView.centerYAnchor),
            usernameLabel.leadingAnchor.constraint(equalTo: profilePhotoImageView.trailingAnchor, constant: 10),
            usernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: menuButton.leadingAnchor, constant: -10),
            usernameLabel.heightAnchor.constraint(equalTo: headerContainerView.heightAnchor),
            
            menuButton.centerYAnchor.constraint(equalTo: headerContainerView.centerYAnchor),
            menuButton.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            menuButton.heightAnchor.constraint(equalTo: headerContainerView.heightAnchor),
            menuButton.widthAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    func setupContentView() {
        contentView.addSubview(postImageView)
        self.imageViewHeightConstraint = postImageView.heightAnchor.constraint(equalTo: contentView.widthAnchor)
        
        NSLayoutConstraint.activate([
            postImageView.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            postImageView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            postImageView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
//            postImageView.bottomAnchor.constraint(equalTo: actionsContainerView.topAnchor),
            self.imageViewHeightConstraint
        ])
    }
    
    func setupActionsView() {
        contentView.addSubview(actionsContainerView)
        actionsContainerView.addSubviews(likeButton, commentButton, bookmarkButton)

        NSLayoutConstraint.activate([
            actionsContainerView.topAnchor.constraint(equalTo: postImageView.bottomAnchor),
            actionsContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            actionsContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            actionsContainerView.heightAnchor.constraint(equalToConstant: 45),
        ])
        
        NSLayoutConstraint.activate([
            likeButton.leadingAnchor.constraint(equalTo: actionsContainerView.leadingAnchor, constant: 13),
            likeButton.centerYAnchor.constraint(equalTo: actionsContainerView.centerYAnchor),
            likeButton.widthAnchor.constraint(equalToConstant: 30),
            likeButton.heightAnchor.constraint(equalToConstant: 30),
            
            commentButton.leadingAnchor.constraint(equalTo: likeButton.trailingAnchor, constant: 10),
            commentButton.centerYAnchor.constraint(equalTo: actionsContainerView.centerYAnchor),
            commentButton.widthAnchor.constraint(equalToConstant: 30),
            commentButton.heightAnchor.constraint(equalToConstant: 30),
            
            bookmarkButton.trailingAnchor.constraint(equalTo: actionsContainerView.trailingAnchor, constant: -10),
            bookmarkButton.centerYAnchor.constraint(equalTo: actionsContainerView.centerYAnchor),
            bookmarkButton.widthAnchor.constraint(equalToConstant: 30),
            bookmarkButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func setupCommentsSection() {
        
    }
    
    func setupFooter() {
        contentView.addSubview(footerContainerView)
        
        footerContainerView.addSubviews(likesLabel, timeSincePostedLabel, captionLabel)
        
        let bottomConstraint = footerContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        bottomConstraint.priority = UILayoutPriority(999)
        
        NSLayoutConstraint.activate([
            footerContainerView.topAnchor.constraint(equalTo: actionsContainerView.bottomAnchor),
            footerContainerView.leadingAnchor.constraint(equalTo: actionsContainerView.leadingAnchor),
            footerContainerView.trailingAnchor.constraint(equalTo: actionsContainerView.trailingAnchor),
            bottomConstraint
        ])
        
        NSLayoutConstraint.activate([
            likesLabel.topAnchor.constraint(equalTo: footerContainerView.topAnchor),
            likesLabel.leadingAnchor.constraint(equalTo: likeButton.leadingAnchor),
            likesLabel.trailingAnchor.constraint(lessThanOrEqualTo: footerContainerView.trailingAnchor, constant: 10),
            likesLabel.heightAnchor.constraint(equalToConstant: 15),
            
            captionLabel.topAnchor.constraint(equalTo: likesLabel.bottomAnchor, constant: 10),
            captionLabel.leadingAnchor.constraint(equalTo: footerContainerView.leadingAnchor, constant: 10),
            captionLabel.trailingAnchor.constraint(equalTo: footerContainerView.trailingAnchor),
            
            timeSincePostedLabel.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 10),
            timeSincePostedLabel.leadingAnchor.constraint(equalTo: captionLabel.leadingAnchor),
            timeSincePostedLabel.trailingAnchor.constraint(lessThanOrEqualTo: captionLabel.trailingAnchor, constant: 10),
            timeSincePostedLabel.bottomAnchor.constraint(equalTo: footerContainerView.bottomAnchor, constant: -15)
        ])
    }
    
    
    //MARK: Configure Post
    
    func configureHeader(profilePhotoURL: URL, username: String) {
        profilePhotoImageView.sd_setImage(with: profilePhotoURL)
        usernameLabel.text = username
    }
    
    func configureImageView(with photo: UIImage) {
        postImageView.image = photo
        let imageAspectRatio = photo.size.height / photo.size.width
        self.imageViewHeightConstraint.isActive = false
        let heightConstraint = NSLayoutConstraint(item: postImageView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: contentView, attribute: NSLayoutConstraint.Attribute.width, multiplier: imageAspectRatio, constant: 0)
        self.imageViewHeightConstraint = heightConstraint
        self.imageViewHeightConstraint.isActive = true
        self.layoutIfNeeded()
    }
    
    func configureFooter(username: String, caption: String, likesCount: Int, postDate: Date) {
        if !caption.isEmpty {
            let attributedUsername = NSAttributedString(string: "\(username) ", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.label])
            let attributedCaption = NSAttributedString(string: caption, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.label])
            
            let usernameWithCaption = NSMutableAttributedString()
            usernameWithCaption.append(attributedUsername)
            usernameWithCaption.append(attributedCaption)
            captionLabel.attributedText = usernameWithCaption
            captionLabel.sizeToFit()
            self.layoutIfNeeded()
        }
        
        let formattedDate = postDate.formatted(date: .abbreviated, time: .omitted)
        timeSincePostedLabel.text = "\(formattedDate)"
        
        setLikes(likesCount: likesCount)
    }
    
    func configure(forPost post: UserPost, postIndex: Int) {
        configureHeader(profilePhotoURL: URL(string: post.author.profilePhotoURL)!, username: post.author.username)
        configureImageView(with: post.image!)
        configureFooter(username: post.author.username, caption: post.caption, likesCount: post.likeCount, postDate: post.postedDate)
        LikeSystemService.shared.getLikesCountForPost(id: post.postID) { likeCount in
            self.setLikes(likesCount: likeCount)
        }
        post.checkIfLikedByCurrentUser { likeState in
            self.configureLikeButton(likeState: likeState)
        }
        self.post = post
        self.index = postIndex
    }
    
    func setLikes(likesCount: Int) {
        if likesCount == 1 {
            likesLabel.text = "\(likesCount) like"
        } else {
            likesLabel.text = "\(likesCount) likes"
        }
    }
    
    
    //MARK: Actions Setup
    
    @objc func menuButtonTapped() {
        guard let post = self.post, let index = index else {
            return
        }
        
        delegate?.menuButtonTapped(forPost: post.postID, atIndex: index)
    }
    
    @objc func likeButtonTapped() {
        guard let post = self.post else {
            return
        }
        delegate?.didTapLikeButton(postID: post.postID, postActionsCell: self)
    }
    
    @objc func commentButtonTapped() {
        guard let post = self.post else {
            return
        }
        delegate?.didTapCommentButton(post: post)
    }
    
    @objc func userTapped() {
        guard let post = self.post, let index = index else {
            return
        }
        delegate?.didSelectUser(userID: post.author.userID, atIndex: index)
    }
    
    //MARK: Additional Setup
    func addGestureRecognizers() {
        let userNameGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(userTapped))
        let profileImageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(userTapped))
        
        usernameLabel.isUserInteractionEnabled = true
        usernameLabel.addGestureRecognizer(userNameGestureRecognizer)
        
        profilePhotoImageView.isUserInteractionEnabled = true
        profilePhotoImageView.addGestureRecognizer(profileImageGestureRecognizer)
        
    }
}



// Like button methods
extension PostTableViewCell {
    
    func configureLikeButton(likeState: PostLikeState) {
        self.likeButtonState = likeState
        switch likeState {
        case .liked:
            showLikedButton(animated: false)
        case .notLiked:
            showLikeButton(animated: false)
        }
    }
    
    func switchLikeButton() {
        guard likeButtonState != nil else {
            return
        }
        switch likeButtonState {
            
        case .liked:
            showLikeButton()
        case .notLiked:
            showLikedButton()
        case .none:
            print("Like state isn't initialized")
            return
        }
    }
    
    func showLikeButton(animated: Bool = true) {
        if animated {
            UIView.animateKeyframes(withDuration: 0.2, delay: 0) {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                    self.likeButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.likeButton.transform = .identity
                    self.likeButton.setImage(UIImage(systemName: "heart", withConfiguration: UIImage.SymbolConfiguration(pointSize: 29)), for: .normal)
                    self.likeButton.tintColor = .label
                }
            }
        } else {
            likeButton.setImage(UIImage(systemName: "heart", withConfiguration: UIImage.SymbolConfiguration(pointSize: 29)), for: .normal)
            likeButton.tintColor = .label
        }
        
    }
    
    func showLikedButton(animated: Bool = true) {
        if animated {
            UIView.animateKeyframes(withDuration: 0.2, delay: 0) {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                    self.likeButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.likeButton.transform = .identity
                    self.likeButton.setImage(UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 29)), for: .normal)
                    self.likeButton.tintColor = .systemRed
                }
            }
        } else {
            likeButton.setImage(UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 29)), for: .normal)
            likeButton.tintColor = .systemRed
        }
    }
}
