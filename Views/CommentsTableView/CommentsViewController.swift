//
//  File.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 17.05.2023.
//

import UIKit

protocol CommentsTableViewActionsProtocol: PostTableViewCellProtocol, CommentCellProtocol {}

class CommentsViewController: UIViewController {

    let viewModel: CommentsTableViewVM

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
        return tableView
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .medium)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        return indicatorView
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
    init(post: UserPost, commentIDToFocusOn: String? = nil, shouldShowRelatedPost: Bool, service: CommentsService) {
        self.viewModel = CommentsTableViewVM(
            post: post,
            commentIDToFocusOn: commentIDToFocusOn,
            shouldShowRelatedPost: shouldShowRelatedPost,
            service: service)
        super.init(nibName: nil, bundle: nil)
        keyboardAccessoryView.delegate = self
    }

    init(postViewModel: PostViewModel, commentIDToFocusOn: String? = nil, shouldShowRelatedPost: Bool, service: CommentsService) {
        self.viewModel = CommentsTableViewVM(
            postViewModel: postViewModel,
            commentIDToFocusOn: commentIDToFocusOn,
            shouldShowRelatedPost: shouldShowRelatedPost,
            service: service)
        super.init(nibName: nil, bundle: nil)
        keyboardAccessoryView.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        view.addSubviews(tableView, loadingIndicator)
        setupKeyboardEventsObservers()
        setupConstraints()
        self.loadingIndicator.startAnimating()
        keyboardAccessoryView.configure(with: viewModel.getCurrentUserProfilePicture())
        self.viewModel.hasInitialzied.bind { hasIntialized in
            if hasIntialized {
                self.setupFactory()
                self.setupDataSource()
                self.showTableView()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        self.hasFinishedAppearing = true
        showTableView()
    }

    // MARK: Constraints setup
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            loadingIndicator.heightAnchor.constraint(equalToConstant: 50),
            loadingIndicator.widthAnchor.constraint(equalToConstant: 50)
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

    private func showTableView() {
        guard viewModel.hasInitialzied.value == true,
        self.hasFinishedAppearing,
        tableView.alpha == 0
        else {
            return
        }

        UIView.animateKeyframes(withDuration: 0.7, delay: 0) {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                self.loadingIndicator.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
                self.loadingIndicator.alpha = 0
            }

            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                self.tableView.alpha = 1
            }
        } completion: { _ in
            self.loadingIndicator.stopAnimating()
            self.loadingIndicator.removeFromSuperview()
            self.scrollToSelectedCommentIfNeeded()
        }
    }

    private func scrollToSelectedCommentIfNeeded() {
        if let indexPath = viewModel.indexPathOfCommentToToFocusOn,
           viewModel.hasAlreadyFocusedOnComment != true {
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }

    private func markNewlyCreatedCommentAsSeen(comment: CommentViewModel) {
        guard let indexPath = viewModel.indexPathOfCommentToToFocusOn else {
            return
        }
        let cell = tableView.cellForRow(at: indexPath) as? CommentTableViewCell
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            UIView.animate(withDuration: 0.6) {
                cell?.backgroundColor = .systemBackground
            } completion: { _ in
                comment.shouldBeMarkedUnseed = false
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
            cell?.backgroundColor = ColorScheme.unseenEventLightBlue
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                cell?.backgroundColor = .systemBackground
            }
            self.viewModel.hasAlreadyFocusedOnComment = true
        }
    }

    private func showCreatedCommentIfNeeded(isTriggeredAfterScroll: Bool = false) {
        guard viewModel.shouldShowNewlyCreatedComment else {
            print("shouldShowCreatedComment Guard")
            return
        }

        guard isCommentsScrolledToTop() else {
            self.scrollToFirstRow()
            print("isCommentsScrolledToTop Guard")
            return
        }

        guard let createdComment = viewModel.getLatestComment() else {
            print("let createdComment Guard")
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
            self.tableView.scrollRectToVisible(areaToFocusOn, animated: true)
        } else {
            self.tableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        }
        viewModel.isAlreadyScrolling = true
    }

    private func isCommentsScrolledToTop() -> Bool {
        let areaToFocusOnMinY = Int(areaToFocusOnCommentPost().minY)
        let currentYContentOffset = Int(tableView.contentOffset.y)
        return areaToFocusOnMinY == currentYContentOffset
    }

    private func areaToFocusOnCommentPost() -> CGRect {
        if viewModel.shouldShowRelatedPost {
            let firstRowRect = tableView.rectForRow(at: IndexPath(row: 0, section: factory.getCommentSectionIndex()))
            let rectWithOffset = firstRowRect.inset(by: UIEdgeInsets(top: -100, left: 0, bottom: 0, right: 0))
            return rectWithOffset
        } else {
            return tableView.rect(forSection: 0)
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
        viewModel.postComment(commentText: commentText) { newlyCreatedComment in
            self.viewModel.insertNewlyCreatedComment(comment: newlyCreatedComment)
            self.showCreatedCommentIfNeeded()
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
            self.viewModel.deleteThisPost {
                sendNotificationToUpdateUserProfile()
                sendNotificationToUpdateUserFeed()
                self.navigationController?.popViewController(animated: true)
            }
        })
    }

    func didTapPostAuthor(cell: PostTableViewCell) {
        let postVM = viewModel.getPostViewModel()
        let user = postVM.author
        showProfile(of: user)
    }

    func didTapLikeButton(cell: PostTableViewCell, completion: @escaping (LikeState) -> Void) {
        viewModel.likeThisPost { likeState in
            completion(likeState)
        }
    }

    func didTapCommentButton(cell: PostTableViewCell) {
        tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
    }

    func didTapBookmarkButton(cell: PostTableViewCell, completion: @escaping (BookmarkState) -> Void) {
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
            viewModel.deleteComment(at: indexPath) {
                self.factory?.deleteComment(at: indexPath)
            }
        }
    }
}
