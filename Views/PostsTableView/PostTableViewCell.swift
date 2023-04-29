//
//  PostTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 20.01.2023.
//

import UIKit
import SDWebImage

protocol PostTableViewCellProtocol: AnyObject {
    func menuButtonTapped(postIndex: IndexPath)
    func didTapPostAuthor(postIndex: IndexPath)
    func didTapLikeButton(postIndex: IndexPath, completion: @escaping (LikeState) -> Void)
    func didTapCommentButton(postIndex: IndexPath)
    func didTapBookmarkButton(postIndex: IndexPath, completion: @escaping (BookmarkState) -> Void)
}

class PostTableViewCell: UITableViewCell {
    
    static let identifier = "PostTableViewCell"
    
    var delegate: PostTableViewCellProtocol?
    var likeButtonState: LikeState = .notLiked
    var bookmarkButtonState: BookmarkState = .notBookmarked
    var indexPath: IndexPath?
    var post: PostViewModel?
    var likeHapticFeedbackGenerator = UINotificationFeedbackGenerator()
    
    var imageViewHeightConstraint: NSLayoutConstraint!
    
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
    
    override func prepareForReuse() {
        captionLabel.text?.removeAll()
    }
    
    
    //MARK: Post Header Views
    
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
        label.backgroundColor = .systemBackground
        label.textColor = .label
        return label
    }()
    
    private let menuButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 19)), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: #selector(menuButtonTapped), for: .touchUpInside)
        button.backgroundColor = .systemBackground
        button.isOpaque = true
        return button
    }()
    
    //MARK: Post Content View
    
    let postImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .systemCyan
        imageView.clipsToBounds = true
        return imageView
    }()
    
    //MARK: Post Actions Views
    
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
        button.isOpaque = true
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
        button.isOpaque = true
        button.addTarget(self, action: #selector(commentButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let bookmarkButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "bookmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 29)), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.isOpaque = true
        button.backgroundColor = .systemBackground
        button.tintColor = .label
        button.addTarget(self, action: #selector(bookmarkButtonTapped), for: .touchUpInside)
        return button
    }()
    
    //MARK: Post Footer Views
    
    private let footerContainerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 5
        stackView.distribution = .fillProportionally
        return stackView
    }()
    
    private let likesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.backgroundColor = .systemBackground
        label.textColor = .label
        //        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var captionLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .systemBackground
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var viewCommentsButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitleColor(.secondaryLabel, for: .normal)
        //        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .left
        button.isHidden = true
        button.backgroundColor = .systemBackground
        button.isOpaque = true
        button.addTarget(self, action: #selector(commentButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let timeSincePostedLabel: UILabel = {
        let label = UILabel()
        //        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.backgroundColor = .systemBackground
        return label
    }()
    
    //MARK: Constraints setup
    
    private func setupHeader() {
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
    
    private func setupContentView() {
        contentView.addSubview(postImageView)
        self.imageViewHeightConstraint = postImageView.heightAnchor.constraint(equalTo: contentView.widthAnchor)
        
        NSLayoutConstraint.activate([
            postImageView.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            postImageView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            postImageView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            self.imageViewHeightConstraint
        ])
    }
    
    private func setupActionsView() {
        contentView.addSubview(actionsContainerView)
        actionsContainerView.addSubviews(likeButton, commentButton, bookmarkButton)
        
        NSLayoutConstraint.activate([
            actionsContainerView.topAnchor.constraint(equalTo: postImageView.bottomAnchor),
            actionsContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            actionsContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            actionsContainerView.heightAnchor.constraint(equalToConstant: 45),
        ])
        
        NSLayoutConstraint.activate([
            likeButton.leadingAnchor.constraint(equalTo: profilePhotoImageView.leadingAnchor),
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
    
    private func setupFooter() {
        contentView.addSubview(footerContainerStackView)
        
        let bottomConstraint = footerContainerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        bottomConstraint.priority = UILayoutPriority(999)
        
        NSLayoutConstraint.activate([
            footerContainerStackView.topAnchor.constraint(equalTo: actionsContainerView.bottomAnchor),
            footerContainerStackView.leadingAnchor.constraint(equalTo: likeButton.leadingAnchor, constant: 5),
            footerContainerStackView.trailingAnchor.constraint(equalTo: actionsContainerView.trailingAnchor),
            bottomConstraint
        ])
        
        footerContainerStackView.addArrangedSubviews(likesLabel, captionLabel, viewCommentsButton, timeSincePostedLabel)
    }
    
    
    //MARK: Configure Post
    
    func configure(with viewModel: PostViewModel, for postIndex: IndexPath) {
        configureHeader(profilePhoto: viewModel.authorProfilePhoto, username: viewModel.authorUsername)
        configureImageView(with: viewModel.postImage)
        configureFooter(username: viewModel.authorUsername, caption: viewModel.postCaption, likesTitle: viewModel.likesCountTitle, timeSincePostedTitle: viewModel.timeSincePostedTitle)
    
        setCommentsTitle(title: viewModel.commentsCountTitle)
        configureLikeButton(likeState: viewModel.likeState, isUserInitiated: false)
        setBookmarkButtonState(state: viewModel.bookmarkState, animated: false)
        self.indexPath = postIndex
        self.likeButtonState = viewModel.likeState
        self.bookmarkButtonState = viewModel.bookmarkState
    }
    
    private func configureHeader(profilePhoto: UIImage, username: String) {
        profilePhotoImageView.image = profilePhoto
        usernameLabel.text = username
    }
    
    private func configureImageView(with photo: UIImage) {
        postImageView.image = photo
        print("Photo height: \(photo.size.height) Photo width: \(photo.size.width)")
        let imageAspectRatio = ceil(photo.size.height) / ceil(photo.size.width)
        self.imageViewHeightConstraint.isActive = false
        print("imageAspectRatio: ", imageAspectRatio)
        let heightConstraint = NSLayoutConstraint(item: postImageView,
                                                  attribute: NSLayoutConstraint.Attribute.height,
                                                  relatedBy: NSLayoutConstraint.Relation.equal,
                                                  toItem: contentView,
                                                  attribute: NSLayoutConstraint.Attribute.width,
                                                  multiplier: imageAspectRatio, constant: 0)
        self.imageViewHeightConstraint = heightConstraint
        self.imageViewHeightConstraint.isActive = true
    }
    
    private func configureFooter(username: String, caption: NSMutableAttributedString, likesTitle: String, timeSincePostedTitle: String) {

        captionLabel.attributedText = caption
        captionLabel.sizeToFit()
        
        timeSincePostedLabel.text = timeSincePostedTitle
        
        setLikesTitle(title: likesTitle)
    }
    
    func setLikesTitle(title: String) {
        likesLabel.text = title
    }
    
    func setCommentsTitle(title: String) {
        viewCommentsButton.setTitle(title, for: .normal)
        viewCommentsButton.isHidden = false
    }
    
    
    //MARK: Actions Setup
    @objc func menuButtonTapped() {
        guard let indexPath = indexPath else {
            return
        }
        delegate?.menuButtonTapped(postIndex: indexPath)
    }
    
    @objc func likeButtonTapped(isTriggeredByDoubleTap: Bool = false) {
        guard let postIndex = indexPath else {
            print("no post index: ", indexPath)
            return
        }
        
        if isTriggeredByDoubleTap && likeButtonState == .liked {
            return
        } else {
            delegate?.didTapLikeButton(postIndex: postIndex) { [weak self] likeState in
                self?.configureLikeButton(likeState: likeState, isUserInitiated: true)
                self?.likeButtonState = likeState
            }
            
            if likeButtonState == .notLiked || isTriggeredByDoubleTap {
                likeHapticFeedbackGenerator.notificationOccurred(.success)
            }
        }
    }
    
    @objc func commentButtonTapped() {
        guard let postIndex = indexPath else {
            return
        }
        delegate?.didTapCommentButton(postIndex: postIndex)
    }
    
    @objc func bookmarkButtonTapped() {
        guard let postIndex = indexPath else {
            return
        }
        delegate?.didTapBookmarkButton(postIndex: postIndex) { [weak self] bookmarkState in
            self?.setBookmarkButtonState(state: bookmarkState, animated: false)
        }
    }
    
    @objc func userTapped() {
        guard let postIndex = indexPath else {
            return
        }
        delegate?.didTapPostAuthor(postIndex: postIndex)
    }
    
    //MARK: Gesture Recognizers Setup
    func addGestureRecognizers() {
        let userNameGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(userTapped))
        let profileImageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(userTapped))
        let postDoubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(likeByDoubleTap))
        postDoubleTapGestureRecognizer.numberOfTapsRequired = 2
        
        usernameLabel.isUserInteractionEnabled = true
        usernameLabel.addGestureRecognizer(userNameGestureRecognizer)
        
        profilePhotoImageView.isUserInteractionEnabled = true
        profilePhotoImageView.addGestureRecognizer(profileImageGestureRecognizer)
        
        postImageView.isUserInteractionEnabled = true
        postImageView.addGestureRecognizer(postDoubleTapGestureRecognizer)
    }
}


//MARK: Like button methods
extension PostTableViewCell {
    
    func configureLikeButton(likeState: LikeState, isUserInitiated: Bool) {
        switch likeState {
        case .liked:
            showLikedButton(animated: isUserInitiated)
        case .notLiked:
            showLikeButton(animated: isUserInitiated)
        }
    }
    
    func switchLikeButton() {
        
        switch likeButtonState {
            
        case .liked:
//            likesCount -= 1
            showLikeButton()
        case .notLiked:
//            likesCount += 1
            showLikedButton()
        }
    }
    
    func showLikeButton(animated: Bool = true) {
        if animated {
            
            UIView.animate(withDuration: 0.1) {
                self.likeButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            } completion: { _ in
                self.likeButton.setImage(UIImage(systemName: "heart", withConfiguration: UIImage.SymbolConfiguration(pointSize: 29)), for: .normal)
                UIView.animate(withDuration: 0.1) {
                    self.likeButton.transform = .identity
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
            
            UIView.animate(withDuration: 0.1) {
                self.likeButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            } completion: { _ in
                self.likeButton.setImage(UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 29)), for: .normal)
                UIView.animate(withDuration: 0.1) {
                    self.likeButton.transform = .identity
                    self.likeButton.tintColor = .systemRed
                }
            }
        } else {
            likeButton.setImage(UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 29)), for: .normal)
            likeButton.tintColor = .systemRed
        }
    }
    
    @objc func likeByDoubleTap() {
        likeButtonTapped(isTriggeredByDoubleTap: true)
        let heartImage = UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 70))
        let likeImageView = UIImageView(image: heartImage)
        likeImageView.translatesAutoresizingMaskIntoConstraints = false
        likeImageView.tintColor = .white
        likeImageView.sizeToFit()
        
        postImageView.addSubview(likeImageView)
        NSLayoutConstraint.activate([
            likeImageView.centerYAnchor.constraint(equalTo: postImageView.centerYAnchor),
            likeImageView.centerXAnchor.constraint(equalTo: postImageView.centerXAnchor)
        ])
        likeImageView.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5) {
            likeImageView.transform = .identity
        } completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 0.1) {
                likeImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            } completion: { _ in
                likeImageView.removeFromSuperview()
            }

        }
    }
}

//MARK: Bookmark button methods
extension PostTableViewCell {
    
    func switchBookmarkButton() {
        switch bookmarkButtonState {
        case .bookmarked:
            setBookmarkButtonState(state: .notBookmarked, animated: true)
            bookmarkButtonState = .notBookmarked
        case .notBookmarked:
            setBookmarkButtonState(state: .bookmarked, animated: true)
            bookmarkButtonState = .bookmarked
        }
    }
    
    func setBookmarkButtonState(state: BookmarkState, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.1) {
                self.bookmarkButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            } completion: { _ in
                if state == .bookmarked {
                    self.setBookmarkedState()
                } else {
                    self.setUnmarkedState()
                }
                UIView.animate(withDuration: 0.1) {
                    self.bookmarkButton.transform = .identity
                }
            }
        } else {
            if state == .bookmarked {
                setBookmarkedState()
            } else {
                setUnmarkedState()
            }
        }
    }
    
    func setBookmarkedState() {
        bookmarkButton.setImage(UIImage(systemName: "bookmark.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 29)), for: .normal)
    }
    
    func setUnmarkedState() {
        bookmarkButton.setImage(UIImage(systemName: "bookmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 29)), for: .normal)
    }
}
