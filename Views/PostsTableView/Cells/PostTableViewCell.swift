//
//  PostTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 20.01.2023.
//

import UIKit
import SDWebImage

protocol PostTableViewCellProtocol: AnyObject {
    func menuButtonTapped(cell: PostTableViewCell)
    func didTapPostAuthor(cell: PostTableViewCell)
    func didTapLikeButton(cell: PostTableViewCell, completion: @escaping (Result<LikeState, Error>) -> Void)
    func didTapCommentButton(cell: PostTableViewCell)
    func didTapBookmarkButton(cell: PostTableViewCell, completion: @escaping (Result<BookmarkState, Error>) -> Void)
}

class PostTableViewCell: UITableViewCell {

    static let identifier = "PostTableViewCell"

    weak var delegate: PostTableViewCellProtocol?

    var post: PostViewModel?
    var likeHapticFeedbackGenerator = UINotificationFeedbackGenerator()

    private var postImageViewHeightConstraint: NSLayoutConstraint!

    static let headerHeight: CGFloat = 50

    // MARK: Post Header Views

    private let headerContainerView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()

    private let profilePhotoImageView: ProfilePictureImageView = {
        let imageView = ProfilePictureImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = CustomFonts.boldFont(ofSize: 14)
        label.backgroundColor = Colors.background
        label.textColor = Colors.label
        return label
    }()

    private lazy var menuButton: UIButton = {
        let button = UIButton()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 19)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "ellipsis", withConfiguration: imageConfig), for: .normal)
        button.tintColor = Colors.label
        button.addTarget(self, action: #selector(menuButtonTapped), for: .touchUpInside)
        button.backgroundColor = Colors.background
        button.isOpaque = true
        return button
    }()

    // MARK: Post Content View

    let postImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = Colors.backgroundSecondary
        imageView.clipsToBounds = true
        return imageView
    }()

    // MARK: Post Actions Views

    private let actionsContainerView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()

    private lazy var likeButton: LikeButton = {
        let button = LikeButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var commentButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "commentIcon"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.tintColor = Colors.label
        button.backgroundColor = Colors.background
        button.isOpaque = true
        button.addTarget(self, action: #selector(commentButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var bookmarkButton: BookmarkButton = {
        let button = BookmarkButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(bookmarkButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: Post Footer Views

    private let footerContainerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
        stackView.distribution = .equalSpacing
        return stackView
    }()

    private let likesLabel: UILabel = {
        let label = UILabel()
        label.font = CustomFonts.boldFont(ofSize: 14)
        label.backgroundColor = Colors.background
        label.textColor = Colors.label
        return label
    }()

    private lazy var captionLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = Colors.background
        label.numberOfLines = 0
        return label
    }()

    private lazy var viewCommentsButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = CustomFonts.regularFont(ofSize: 14)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.contentHorizontalAlignment = .left
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        button.configuration?.titlePadding = 0
        button.configuration?.contentInsets = .zero
        button.backgroundColor = Colors.background
        button.isHidden = true
        button.isOpaque = true
        button.addTarget(self, action: #selector(commentButtonTapped), for: .touchUpInside)
        return button
    }()

    private let timeSincePostedLabel: UILabel = {
        let label = UILabel()
        label.font = CustomFonts.regularFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.backgroundColor = Colors.background
        return label
    }()

    // MARK: Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = Colors.background
        selectionStyle = .none
        clipsToBounds = true
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Constraints setup

    private func setupViews() {
        setupHeader()
        setupContentView()
        setupActionsView()
        setupFooter()
        addGestureRecognizers()
    }

    private func setupHeader() {
        contentView.addSubview(headerContainerView)
        headerContainerView.addSubviews(profilePhotoImageView, usernameLabel, menuButton)
        profilePhotoImageView.layer.cornerRadius = 35 / 2

        NSLayoutConstraint.activate([
            headerContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerContainerView.heightAnchor.constraint(equalToConstant: PostTableViewCell.headerHeight)
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

        self.postImageViewHeightConstraint = postImageView.heightAnchor.constraint(equalToConstant: 100)
        NSLayoutConstraint.activate([
            postImageView.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            self.postImageViewHeightConstraint
        ])
    }

    private func setupActionsView() {
        contentView.addSubview(actionsContainerView)
        actionsContainerView.addSubviews(likeButton, commentButton, bookmarkButton)

        NSLayoutConstraint.activate([
            actionsContainerView.topAnchor.constraint(equalTo: postImageView.bottomAnchor),
            actionsContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            actionsContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            actionsContainerView.heightAnchor.constraint(equalToConstant: 45)
        ])

        NSLayoutConstraint.activate([
            likeButton.centerXAnchor.constraint(equalTo: profilePhotoImageView.centerXAnchor),
            likeButton.centerYAnchor.constraint(equalTo: actionsContainerView.centerYAnchor),
            likeButton.widthAnchor.constraint(equalToConstant: 25),
            likeButton.heightAnchor.constraint(equalToConstant: 25),

            commentButton.leadingAnchor.constraint(equalTo: likeButton.trailingAnchor, constant: 15),
            commentButton.centerYAnchor.constraint(equalTo: actionsContainerView.centerYAnchor),
            commentButton.widthAnchor.constraint(equalToConstant: 25),
            commentButton.heightAnchor.constraint(equalToConstant: 23),

            bookmarkButton.trailingAnchor.constraint(equalTo: actionsContainerView.trailingAnchor, constant: -10),
            bookmarkButton.centerYAnchor.constraint(equalTo: actionsContainerView.centerYAnchor),
            bookmarkButton.widthAnchor.constraint(equalToConstant: 25),
            bookmarkButton.heightAnchor.constraint(equalToConstant: 25)
        ])
    }

    private func setupFooter() {
        contentView.addSubview(footerContainerStackView)
        let bottomConstraint = footerContainerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        bottomConstraint.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            footerContainerStackView.topAnchor.constraint(equalTo: actionsContainerView.bottomAnchor, constant: 5),
            footerContainerStackView.leadingAnchor.constraint(equalTo: likeButton.leadingAnchor, constant: 5),
            footerContainerStackView.trailingAnchor.constraint(equalTo: bookmarkButton.trailingAnchor, constant: -5),
            bottomConstraint,
            viewCommentsButton.heightAnchor.constraint(equalToConstant: 15)
        ])

        footerContainerStackView.addArrangedSubviews(likesLabel, captionLabel, viewCommentsButton, timeSincePostedLabel)
    }

    // MARK: Configure Post
    func configure(with viewModel: PostViewModel) {
        configureViews(viewModel: viewModel)
    }

    private func configureViews(viewModel: PostViewModel) {
        if viewModel.isNewlyCreated { self.contentView.alpha = 0 }
        let profilePhoto = viewModel.author.getProfilePhoto()
        configureHeader(profilePhoto: profilePhoto!,
                        username: viewModel.author.username,
                        isCurrentUserPost: viewModel.isMadeByCurrentUser)
        configureImageView(for: viewModel.postImage)
        configureFooter(
            username: viewModel.author.username,
            caption: viewModel.postCaption,
            likesTitle: viewModel.likesCountTitle,
            timeSincePostedTitle: viewModel.timeSincePostedTitle)

        setCommentsTitle(title: viewModel.commentsCountTitle)
        likeButton.setLikeButtonState(likeState: viewModel.likeState, isUserInitiated: false)
        bookmarkButton.setBookmarkButtonState(state: viewModel.bookmarkState, animated: false)
    }

    private func configureHeader(profilePhoto: UIImage, username: String, isCurrentUserPost: Bool) {
        profilePhotoImageView.image = profilePhoto
        usernameLabel.text = username
        if isCurrentUserPost {
            menuButton.isHidden = false
        } else {
            menuButton.isHidden = true
        }
    }

    private func configureImageView(for image: UIImage) {
        postImageView.image = image
        let imageAspectRatio = (image.size.height) / (image.size.width)
        self.postImageViewHeightConstraint?.isActive = false
        self.postImageViewHeightConstraint = NSLayoutConstraint(
            item: postImageView,
            attribute: NSLayoutConstraint.Attribute.height,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: contentView,
            attribute: NSLayoutConstraint.Attribute.width,
            multiplier: imageAspectRatio, constant: 0)
        self.postImageViewHeightConstraint?.isActive = true
        self.layoutIfNeeded()
    }

    private func configureFooter(username: String, caption: NSMutableAttributedString?, likesTitle: String, timeSincePostedTitle: String) {
        if let caption = caption {
            captionLabel.attributedText = caption
            captionLabel.sizeToFit()
        } else {
            captionLabel.removeFromSuperview()
        }
        timeSincePostedLabel.text = timeSincePostedTitle
        setLikesTitle(title: likesTitle)
    }

    func setLikesTitle(title: String) {
        likesLabel.text = title
    }

    func setCommentsTitle(title: String?) {
        guard let title = title else {
            viewCommentsButton.isHidden = true
            return
        }
        viewCommentsButton.setTitle(title, for: .normal)
        viewCommentsButton.isHidden = false
    }

    func makePostVisible(animationCompletion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.4) {
            self.contentView.alpha = 1
        } completion: { _ in
            animationCompletion()
        }
    }

    // MARK: Actions Setup
    @objc func menuButtonTapped() {
        delegate?.menuButtonTapped(cell: self)
    }

    @objc func likeButtonTapped(isTriggeredByDoubleTap: Bool = false) {

        if isTriggeredByDoubleTap && self.likeButton.buttonState == .liked {
            return
        } else {
            delegate?.didTapLikeButton(cell: self) { [weak self] result in
                if case .success(let newlikeState) = result {
                    self?.likeButton.setLikeButtonState(likeState: newlikeState, isUserInitiated: true)

                    if newlikeState == .liked || isTriggeredByDoubleTap {
                        self?.likeHapticFeedbackGenerator.notificationOccurred(.success)
                    }
                }
            }
        }
    }

    @objc func commentButtonTapped() {
        delegate?.didTapCommentButton(cell: self)
    }

    @objc func bookmarkButtonTapped() {
        delegate?.didTapBookmarkButton(cell: self) { [weak self] result in
            if case .success(let newbookmarkState) = result {
                self?.bookmarkButton.setBookmarkButtonState(state: newbookmarkState, animated: true)
            }
        }
    }

    @objc func userTapped() {
        delegate?.didTapPostAuthor(cell: self)
    }

    // MARK: Gesture Recognizers Setup
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

// MARK: Like button methods
extension PostTableViewCell {

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
