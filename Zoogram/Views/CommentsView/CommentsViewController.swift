//
//  File.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 17.05.2023.
//

import UIKit

@MainActor protocol CommentsTableViewDelegateProtocol: PostTableViewCellProtocol, CommentCellProtocol {}

class CommentsViewController: ViewControllerWithLoadingIndicator {

    private var readyToBecomeFirstResponder: Bool = false
    private let viewModel: CommentsViewModel
    private(set) var factory: CommentListFactory!
    private(set) var dataSource: TableViewDataSource?
    private var previousAccessoryViewHeight: CGFloat = 0

    private var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.keyboardDismissMode = .interactive
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.alpha = 0
        tableView.backgroundColor = Colors.background
        return tableView
    }()

    private lazy var noCommentsView: PlaceholderView = {
        let view = PlaceholderView(
            imageName: "message",
            text: String(localized: "Be the first to leave a comment"),
            imagePointSize: 45)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.imageView.tintColor = .tertiaryLabel
        view.label.textColor = .tertiaryLabel
        view.label.font = CustomFonts.boldFont(ofSize: 17)
        return view
    }()

    private lazy var keyboardAccessoryView: CommentAccessoryView = {
        let commentAccessoryView = CommentAccessoryView()
        commentAccessoryView.translatesAutoresizingMaskIntoConstraints = false
        return commentAccessoryView
    }()

    var accessoryViewTopAnchor: NSLayoutYAxisAnchor {
        return keyboardAccessoryView.topAnchor
    }

    // MARK: Init
    init(post: UserPost, commentIDToFocusOn: String? = nil, shouldShowRelatedPost: Bool, service: CommentsServiceProtocol) {
        self.viewModel = CommentsViewModel(
            post: post,
            commentIDToFocusOn: commentIDToFocusOn,
            shouldShowRelatedPost: shouldShowRelatedPost,
            service: service)
        super.init()
    }

    init(postViewModel: PostViewModel, commentIDToFocusOn: String? = nil, shouldShowRelatedPost: Bool, service: CommentsServiceProtocol) {
        self.viewModel = CommentsViewModel(
            postViewModel: postViewModel,
            commentIDToFocusOn: commentIDToFocusOn,
            shouldShowRelatedPost: shouldShowRelatedPost,
            service: service)
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Colors.background
        self.mainView = tableView
        title = String(localized: "Comments")
        setupConstraints()
        setupKeyboardAccessoryView()
        fetchComments()
        setupKeyboardEventsObservers()
        keyboardAccessoryView.delegate = self
        setupBackButtonAction()
        reloadAction = { self.fetchComments() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        UserDefaults().setValue(true, forKey: UserDefaultsKeys.shouldShowPendingNotification.rawValue)
    }

    // MARK: Views setup
    private func setupConstraints() {
        view.addSubviews(tableView, keyboardAccessoryView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            keyboardAccessoryView.topAnchor.constraint(equalTo: tableView.bottomAnchor),
            keyboardAccessoryView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardAccessoryView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            keyboardAccessoryView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupKeyboardAccessoryView() {
        Task {
            await viewModel.getCurrentUserModel()
            let userPfp = viewModel.getCurrentUserProfilePicture()
            keyboardAccessoryView.configure(with: userPfp)
        }
    }

    private func setupKeyboardEventsObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
    }

    private func setupBackButtonAction() {
        navigationItem.backAction = UIAction(handler: { _ in
            self.keyboardAccessoryView.resign()
            if self.viewModel.hasPendingComments {
                let userDefaultsKey = UserDefaultsKeys.shouldShowPendingNotification.rawValue
                let shouldShowNotification = UserDefaults().bool(forKey: userDefaultsKey)

                if shouldShowNotification {
                    self.showPendingCommentsNotification()
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        })
    }

    // MARK: Main methods

    private func showPendingCommentsNotification() {
        let title = String(localized: "Pending comments")
        let message = String(localized: "You have pending comments, they'll be published once there's an active connection.")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        }

        let dontShowTitle = String(localized: "Don't show again")
        let shouldShowPendingNotificationKey = UserDefaultsKeys.shouldShowPendingNotification.rawValue
        let dontShowAction = UIAlertAction(title: dontShowTitle, style: .default) { _ in
            UserDefaults().setValue(false, forKey: shouldShowPendingNotificationKey)
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(okAction)
        alert.addAction(dontShowAction)
        self.present(alert, animated: true)
    }

    private func showNoCommentsViewIfNeeded() {
        guard self.viewModel.comments.isEmpty && self.viewModel.shouldShowRelatedPost == false else { return }
        noCommentsView.alpha = 1
        tableView.addSubview(noCommentsView)
        NSLayoutConstraint.activate([
            noCommentsView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            noCommentsView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            noCommentsView.widthAnchor.constraint(equalTo: tableView.widthAnchor, constant: -20)
        ])
    }

    private func removeNoCommentsView() {
        guard self.noCommentsView.superview != nil else { return }
        UIView.animate(withDuration: 0.2) {
            self.noCommentsView.alpha = 0
        } completion: { _ in
            self.noCommentsView.removeFromSuperview()
        }
    }

    private func fetchComments() {
        Task {
            do {
                try await viewModel.fetchData()
                showCommentsTableView()
            } catch {
                showCommentsTableView()
                self.showPopUp(issueText: error.localizedDescription)
            }
        }
    }

    private func showCommentsTableView() {
        self.setupFactory()
        self.setupDataSource()
        self.showMainView {
            self.scrollToSelectedCommentIfNeeded()
        }
        self.showNoCommentsViewIfNeeded()
    }

    private func scrollToSelectedCommentIfNeeded() {
        if let indexPath = viewModel.indexPathOfCommentToToFocusOn,
           viewModel.hasAlreadyFocusedOnComment != true {
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }

    private func markNewlyCreatedCommentAsSeen() {
        guard let indexPath = viewModel.indexPathOfCommentToToFocusOn else {
            return
        }
        self.factory.markCommentAsSeen(at: indexPath)
        self.viewModel.comments[indexPath.row].shouldBeMarkedUnseen = false
        self.viewModel.hasAlreadyFocusedOnComment = true
    }

    private func focusOnCommentIfNeeded() {
        guard let indexPath = viewModel.indexPathOfCommentToToFocusOn,
              viewModel.hasAlreadyFocusedOnComment == false
        else {
            return
        }
        self.factory.focusOnComment(at: indexPath)
        self.viewModel.hasAlreadyFocusedOnComment = true
    }

    private func showCreatedComment() {
        guard let createdComment = viewModel.getLatestComment() else { return }
        let indexPath = IndexPath(row: 0, section: self.factory.getCommentSectionIndex())
        self.factory?.insertComment(with: createdComment, at: indexPath) {
            self.tableView.scrollToRow(at: indexPath, at: .none, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.markNewlyCreatedCommentAsSeen()
            }
        }
    }

    private func markCommentAsPublished(_ comment: PostComment) {
        let commentIndexPath = viewModel.getIndexPathOfComment(comment)
        viewModel.comments[commentIndexPath.row].hasBeenPosted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.factory.markCommentasPublished(at: commentIndexPath)
        }
    }
}

// MARK: Factory & DataSource setup
extension CommentsViewController {

    func setupFactory() {
        self.factory = CommentListFactory(
            for: self.tableView,
            shouldShowRelatedPost: viewModel.shouldShowRelatedPost,
            delegate: self)
    }

    func setupDataSource() {
        self.factory.buildSections(for: self.viewModel)
        let dataSource = DefaultTableViewDataSource(sections: factory.sections)
        dataSource.delegate = self
        self.dataSource = dataSource
        self.tableView.dataSource = dataSource
        self.tableView.delegate = dataSource
        self.viewModel.commentSectionIndex = factory.getCommentSectionIndex()
        self.tableView.reloadData()
    }
}

// MARK: Keyboard animation handler
extension CommentsViewController {

    @objc func keyboardWillShow(_ notification: NSNotification) {
        moveTableViewWithKeyboard(notification: notification, keyboardWillShow: true)
    }

    @objc func keyboardWillHide(_ notification: NSNotification) {
        moveTableViewWithKeyboard(notification: notification, keyboardWillShow: false)
    }

    func moveTableViewWithKeyboard(notification: NSNotification, keyboardWillShow: Bool) {
        let numberOfComments = viewModel.comments.count
        guard numberOfComments > 0 else { return }
        guard let keyboardAttributes = KeyboardAnimationAttributes(notification: notification) else { return }
        guard keyboardAttributes.beginKeyboardSize.origin.y != keyboardAttributes.endKeyboardSize.origin.y else { return }

        let commentSectionIndex = factory.getCommentSectionIndex()
        let indexPath = IndexPath(row: numberOfComments - 1, section: commentSectionIndex)
        let lastCommentRect = tableView.rectForRow(at: indexPath)
        let lastCommentRelativeToView = tableView.convert(lastCommentRect, to: view)
        let lastCommentPosition = lastCommentRelativeToView.maxY
        let accessoryViewHeight = keyboardAccessoryView.frame.size.height
        let keyboardPosition = keyboardAttributes.endKeyboardSize.minY - accessoryViewHeight
        guard lastCommentPosition >= keyboardPosition else { return }

        var contentOffset = tableView.contentOffset
        let safeAreaBottomInset = self.view.safeAreaInsets.bottom
        let bottomInset = safeAreaBottomInset
        var offsetValue: CGFloat = 0

        let accessoryViewPosition = keyboardAttributes.beginKeyboardSize.minY - accessoryViewHeight

        if  accessoryViewPosition > tableView.contentSize.height {
            let positionYDifference = lastCommentPosition - keyboardPosition
            offsetValue = positionYDifference
        } else {
            offsetValue = (keyboardAttributes.endKeyboardSize.height - bottomInset)
        }

        if keyboardWillShow {
            contentOffset.y += offsetValue
        } else {
            let offset = keyboardAttributes.beginKeyboardSize.height - bottomInset
            contentOffset.y -= offset
        }

        let animator = UIViewPropertyAnimator(
            duration: keyboardAttributes.keyboardAnimationDuration,
            curve: keyboardAttributes.keyboardAnimationCurve) { [weak self] in
            self?.tableView.setContentOffset(contentOffset, animated: false)
        }

        self.previousAccessoryViewHeight = accessoryViewHeight
        animator.startAnimation()
    }
}

// MARK: TableView Delegate
extension CommentsViewController: TableViewDataSourceDelegate {

    func scrollViewDidEndScrollingAnimation() {
        focusOnCommentIfNeeded()
    }

   func didCommit(editingStyle: UITableViewCell.EditingStyle, at indexPath: IndexPath) {
        if editingStyle == .delete {
            Task {
                do {
                    self.factory?.deleteComment(at: indexPath)
                    self.showNoCommentsViewIfNeeded()
                    try await viewModel.deleteComment(at: indexPath)
                } catch {
                    self.showPopUp(issueText: error.localizedDescription)
                }
            }
        }
    }
}

// MARK: Keyboard accessory action
extension CommentsViewController: CommentAccessoryViewProtocol {
    func sendButtonTapped(commentText: String) {
        Task {
            do {
                let newComment = try viewModel.createPostComment(text: commentText)
                viewModel.insertNewComment(comment: newComment)
                self.removeNoCommentsView()
                self.showCreatedComment()
                try await viewModel.postComment(comment: newComment)
                self.markCommentAsPublished(newComment)
            } catch {
                self.showPopUp(issueText: error.localizedDescription)
            }
        }
    }
}

// MARK: Comments delegate
extension CommentsViewController: CommentsTableViewDelegateProtocol {

    func openUserProfile(of commentAuthor: ZoogramUser) {
        self.showProfile(of: commentAuthor)
    }

    func menuButtonTapped(cell: PostTableViewCell) {
        let postVM = viewModel.getPostViewModel()
        showMenuForPost(postViewModel: postVM, onDelete: {
            Task {
                do {
                    try await self.viewModel.deleteThisPost()
                    sendNotificationToUpdateUserProfile()
                    sendNotificationToUpdateUserFeed()
                    self.navigationController?.popViewController(animated: true)
                } catch {
                    self.showPopUp(issueText: error.localizedDescription)
                }
            }
        })
    }

    func didTapPostAuthor(cell: PostTableViewCell) {
        let postVM = viewModel.getPostViewModel()
        let user = postVM.author
        showProfile(of: user)
    }

    func didTapLikeButton(cell: PostTableViewCell) async throws {
        try await viewModel.likeThisPost()
    }

    func didTapCommentButton(cell: PostTableViewCell) {
        tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
    }

    func didTapBookmarkButton(cell: PostTableViewCell) async throws {
        try await viewModel.bookmarkThisPost()
    }
}
