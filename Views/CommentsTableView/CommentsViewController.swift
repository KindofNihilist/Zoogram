//
//  File.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 17.05.2023.
//

import UIKit

protocol CommentsTableViewActionsProtocol: PostTableViewCellProtocol, CommentCellProtocol {}

class CommentsViewController: ViewControllerWithLoadingIndicator {

    let viewModel: CommentsViewModel
    private(set) var factory: CommentListFactory!
    private(set) var dataSource: TableViewDataSource?
    private var hasFinishedAppearing: Bool = false
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
        return commentAccessoryView
    }()

    override var inputAccessoryView: UIView? {
        return keyboardAccessoryView
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    // MARK: Init
    init(post: UserPost, commentIDToFocusOn: String? = nil, shouldShowRelatedPost: Bool, currentUser: ZoogramUser, service: CommentsServiceProtocol) {
        self.viewModel = CommentsViewModel(
            post: post,
            commentIDToFocusOn: commentIDToFocusOn,
            shouldShowRelatedPost: shouldShowRelatedPost,
            currentUser: currentUser,
            service: service)
        super.init()
        keyboardAccessoryView.delegate = self
    }

    init(postViewModel: PostViewModel, commentIDToFocusOn: String? = nil, shouldShowRelatedPost: Bool, currentUser: ZoogramUser, service: CommentsServiceProtocol) {
        self.viewModel = CommentsViewModel(
            postViewModel: postViewModel,
            commentIDToFocusOn: commentIDToFocusOn,
            shouldShowRelatedPost: shouldShowRelatedPost,
            currentUser: currentUser,
            service: service)
        super.init()
        keyboardAccessoryView.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Colors.background
        self.mainView = tableView
        view.addSubviews(tableView)
        title = String(localized: "Comments")
        setupKeyboardEventsObservers()
        setupConstraints()
        keyboardAccessoryView.configure(with: viewModel.getCurrentUserProfilePicture())
        reloadAction = { self.fetchComments() }
        fetchComments()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        self.viewModel.hasInitialzied.bind { hasIntialized in
            if hasIntialized {
                self.setupFactory()
                self.setupDataSource()
                self.showMainView {
                    self.scrollToSelectedCommentIfNeeded()
                }
                self.showNoCommentsViewIfNeeded()
            }
        }
    }

    private func showNoCommentsViewIfNeeded() {
        guard self.viewModel.comments.isEmpty else { return }
        noCommentsView.alpha = 1
        view.addSubview(noCommentsView)
        NSLayoutConstraint.activate([
            noCommentsView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noCommentsView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            noCommentsView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -20)
        ])
    }

    private func removeNoCommentsViewIfNeeded() {
        guard self.viewModel.comments.isEmpty else { return }
        UIView.animate(withDuration: 0.2) {
            self.noCommentsView.alpha = 0
        } completion: { _ in
            self.noCommentsView.removeFromSuperview()
        }
    }

    private func fetchComments() {
        self.viewModel.fetchData { error in
            if let error = error {
                print(error.localizedDescription)
                self.showLoadingErrorNotification(text: error.localizedDescription)
            }
        }
    }

    // MARK: Constraints setup
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        ])
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

    private func scrollToSelectedCommentIfNeeded() {
        if let indexPath = viewModel.indexPathOfCommentToToFocusOn,
           viewModel.hasAlreadyFocusedOnComment != true {
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }

    private func markNewlyCreatedCommentAsSeen(comment: PostComment) {
        guard let indexPath = viewModel.indexPathOfCommentToToFocusOn else {
            return
        }
        let cell = tableView.cellForRow(at: indexPath) as? CommentTableViewCell
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            UIView.animate(withDuration: 0.6) {
                cell?.backgroundColor = Colors.background
            } completion: { _ in
                comment.shouldBeMarkedUnseen = false
                self.viewModel.hasAlreadyFocusedOnComment = true
            }
        }
    }

    private func focusOnCommentIfNeeded() {
        guard let indexPath = viewModel.indexPathOfCommentToToFocusOn,
              viewModel.hasAlreadyFocusedOnComment == false
        else {
            return
        }
        let cell = tableView.cellForRow(at: indexPath) as? CommentTableViewCell

        UIView.animate(withDuration: 0.5, delay: 0.5) {
            cell?.backgroundColor = Colors.unseenBlue
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                cell?.backgroundColor = Colors.background
            }
            self.viewModel.hasAlreadyFocusedOnComment = true
        }
    }

    private func showCreatedCommentIfNeeded(isTriggeredAfterScroll: Bool = false) {
        guard viewModel.shouldShowNewlyCreatedComment else {
            return
        }

        guard isCommentsScrolledToTop() else {
            self.scrollToFirstRow()
            return
        }

        guard let createdComment = viewModel.getLatestComment() else {
            return
        }

        let delay = isTriggeredAfterScroll ? 0.3 : 0.0

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let indexPath = IndexPath(row: 0, section: self.factory.getCommentSectionIndex())
            self.factory?.insertComment(with: createdComment, at: indexPath) {
                self.viewModel.shouldShowNewlyCreatedComment = false
                self.markNewlyCreatedCommentAsSeen(comment: createdComment)
            }
        }
    }

    func scrollToFirstRow() {
        if viewModel.shouldShowRelatedPost {
            let areaToFocusOn = areaToFocusOnCommentPost()
            self.tableView.setContentOffset(CGPoint(x: 0, y: Int(areaToFocusOn.minY)), animated: true)
        } else {
            self.tableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        }
        viewModel.isAlreadyScrolling = true
    }

    private func isCommentsScrolledToTop() -> Bool {
        guard viewModel.postCaption != nil || viewModel.shouldShowRelatedPost || viewModel.comments.count > 1 else {
            return true
        }
        let areaToFocusOnMinY = Int(areaToFocusOnCommentPost().minY)
        let currentYContentOffset = Int(tableView.contentOffset.y)
        return areaToFocusOnMinY == currentYContentOffset
    }

    private func areaToFocusOnCommentPost() -> CGRect {
        if viewModel.shouldShowRelatedPost {
            let postSectionRect = tableView.rect(forSection: 0)

            guard viewModel.comments.count > 1 else {
                // If currently tableView shows zero comments but viewModel already holds new comment that needs to be inserted
                let offset = tableView.contentSize.height - tableView.frame.height
                return postSectionRect.inset(by: UIEdgeInsets(top: offset + 100, left: 0, bottom: 0, right: 0))
            }

            let commentSectionIndex = factory.getCommentSectionIndex()
            let commentSectionRect = tableView.rect(forSection: commentSectionIndex)
            let firstCommentRect = tableView.rectForRow(at: IndexPath(row: 0, section: commentSectionIndex))
            let commentRectWithInset = firstCommentRect.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: -firstCommentRect.height, right: 0))

            guard commentSectionRect.height >= tableView.frame.height else {
                let contentOffset =  firstCommentRect.maxY - tableView.frame.height
                let postSectionWithInset = postSectionRect.inset(by: UIEdgeInsets(top: contentOffset + 5, left: 0, bottom: 0, right: 0  ))
                return postSectionWithInset
            }
            let rectWithInset = firstCommentRect.inset(by: UIEdgeInsets(top: -100, left: 0, bottom: 0, right: 0))
            return rectWithInset
        } else {
            return tableView.rect(forSection: 0)
        }

    }}

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

extension CommentsViewController {

    @objc func keyboardWillShow(_ notification: NSNotification) {
        moveTableViewWithKeyboard(notification: notification, keyboardWillShow: true)
    }

    @objc func keyboardWillHide(_ notification: NSNotification) {
        moveTableViewWithKeyboard(notification: notification, keyboardWillShow: false)
    }

    func moveTableViewWithKeyboard(notification: NSNotification, keyboardWillShow: Bool) {
        guard tableView.contentSize.height > tableView.frame.height else {
            return
        }
        guard let beginKeyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue else { return }
        guard let endKeyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }

        let keyboardAnimationDuration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        let keyboardAnimationCurve = UIView.AnimationCurve(rawValue: notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! Int)!

        var contentOffset = tableView.contentOffset

        let safeAreaBottomInset = self.view.safeAreaInsets.bottom
        let accessoryViewHeight = keyboardAccessoryView.frame.height
        var bottomInset = safeAreaBottomInset + accessoryViewHeight

        if keyboardWillShow && beginKeyboardSize.height == bottomInset {
            contentOffset.y += (endKeyboardSize.height - bottomInset)
        } else {
            contentOffset.y += (accessoryViewHeight - previousAccessoryViewHeight)
        }

        let animator = UIViewPropertyAnimator(duration: keyboardAnimationDuration, curve: keyboardAnimationCurve) { [weak self] in
            self?.tableView.setContentOffset(contentOffset, animated: false)
        }

        self.previousAccessoryViewHeight = accessoryViewHeight

        animator.startAnimation()
    }
}

// MARK: Post button tapped
extension CommentsViewController: CommentAccessoryViewProtocol {
    func postButtonTapped(commentText: String, completion: @escaping () -> Void) {
        viewModel.postComment(commentText: commentText) { result in
            switch result {
            case .success(let newlyCreatedComment):
                self.removeNoCommentsViewIfNeeded()
                self.viewModel.insertNewlyCreatedComment(comment: newlyCreatedComment)
                self.showCreatedCommentIfNeeded()
            case .failure(let error):
                self.showPopUp(issueText: error.localizedDescription)
            }
            completion()
        }
    }
}

extension CommentsViewController: CommentsTableViewActionsProtocol {

    func openUserProfile(of commentAuthor: ZoogramUser) {
        self.showProfile(of: commentAuthor)
    }

    func menuButtonTapped(cell: PostTableViewCell) {
        let postVM = viewModel.getPostViewModel()
        showMenuForPost(postViewModel: postVM, onDelete: {
            self.viewModel.deleteThisPost { result in
                switch result {
                case .success:
                    sendNotificationToUpdateUserProfile()
                    sendNotificationToUpdateUserFeed()
                    self.navigationController?.popViewController(animated: true)
                case .failure(let error):
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

    func didTapLikeButton(cell: PostTableViewCell, completion: @escaping (Result<LikeState, Error>) -> Void) {
        viewModel.likeThisPost { likeState in
            completion(likeState)
        }
    }

    func didTapCommentButton(cell: PostTableViewCell) {
        tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
    }

    func didTapBookmarkButton(cell: PostTableViewCell, completion: @escaping (Result<BookmarkState, Error>) -> Void) {
        viewModel.bookmarkThisPost { bookmarkState in
            completion(bookmarkState)
        }
    }
}

extension CommentsViewController: TableViewDataSourceDelegate {

    func didSelectCell(at indexPath: IndexPath) {
    }

    func scrollViewDidEndScrollingAnimation() {
        showCreatedCommentIfNeeded(isTriggeredAfterScroll: true)
        focusOnCommentIfNeeded()
        viewModel.isAlreadyScrolling = false
    }

    func didCommit(editingStyle: UITableViewCell.EditingStyle, at indexPath: IndexPath) {
        if editingStyle == .delete {
            viewModel.deleteComment(at: indexPath) { result in
                switch result {
                case .success:
                    self.factory?.deleteComment(at: indexPath)
                    self.showNoCommentsViewIfNeeded()
                case .failure(let error):
                    self.showPopUp(issueText: error.localizedDescription)
                }
            }
        }
    }
}
