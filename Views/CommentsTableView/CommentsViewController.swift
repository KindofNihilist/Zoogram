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

    private(set) var factory: CommentListFactory?

    private(set) var dataSource: TableViewDataSource?

    private var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(CommentTableViewCell.self, forCellReuseIdentifier: CommentTableViewCell.identifier)
        tableView.register(PostTableViewCell.self, forCellReuseIdentifier: PostTableViewCell.identifier)
        tableView.keyboardDismissMode = .interactive
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        return tableView
    }()

    var keyboardAccessoryView: CommentAccessoryView = {
        let commentAccessoryView = CommentAccessoryView()
        return commentAccessoryView
    }()

    override var inputAccessoryView: UIView? {
        return keyboardAccessoryView
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    init(post: UserPost, commentIDToFocusOn: String? = nil, shouldShowRelatedPost: Bool, service: CommentsService) {
        self.viewModel = CommentsTableViewVM(
            post: post,
            commentIDToFocusOn: commentIDToFocusOn,
            shouldShowRelatedPost: shouldShowRelatedPost,
            service: service)
        super.init(nibName: nil, bundle: nil)
        observeKeyboardEvents()
        keyboardAccessoryView.delegate = self
    }

    init(postViewModel: PostViewModel, commentIDToFocusOn: String? = nil, shouldShowRelatedPost: Bool, service: CommentsService) {
        self.viewModel = CommentsTableViewVM(
            postViewModel: postViewModel,
            commentIDToFocusOn: commentIDToFocusOn,
            shouldShowRelatedPost: shouldShowRelatedPost,
            service: service)
        super.init(nibName: nil, bundle: nil)
        observeKeyboardEvents()
        keyboardAccessoryView.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillLayoutSubviews() {
        keyboardAccessoryView.intrinsicHeight = keyboardAccessoryView.accessoryViewHeight + view.safeAreaInsets.bottom
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        setupConstraints()
        keyboardAccessoryView.configure(with: viewModel.getCurrentUserProfilePicture())
        self.viewModel.hasInitialzied.bind { hasIntialized in
            if hasIntialized {
                self.setupFactory()
                self.setupDataSource()
                self.tableView.reloadData()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        scrollToSelectedCommentIfNeeded()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        ])
    }

    private func observeKeyboardEvents() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func scrollToSelectedCommentIfNeeded() {
        if let indexPath = viewModel.indexPathOfCommentToToFocusOn,
           viewModel.hasAlreadyFocusedOnComment != true{
            print("should scroll")
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }

    private func focusOnCommentIfNeeded() {
        guard let indexPath = viewModel.indexPathOfCommentToToFocusOn,
              viewModel.hasAlreadyFocusedOnComment == false
        else {
            return
        }
        let cell = tableView.cellForRow(at: indexPath) as? CommentTableViewCell

        UIView.animate(withDuration: 0.5) {
            cell?.backgroundColor = ColorScheme.unseenEventLightBlue
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                cell?.backgroundColor = .systemBackground
            }
            self.viewModel.hasAlreadyFocusedOnComment = true
        }
    }

    private func showCreatedCommentIfNeeded() {
        guard isCommentsScrolledToTop() else {
            scrollToFirstRow()
            return
        }
        guard viewModel.shouldShowNewlyCreatedComment else {
            return
        }
        let createdComment = viewModel.getComment(for: IndexPath(row: 0, section: 0))
        factory?.insertCommentCell(with: createdComment, with: .automatic) {
            self.viewModel.shouldShowNewlyCreatedComment = false
        }
    }

    func scrollToFirstRow() {
        guard let factory = factory else {
            return
        }
        let commentSection = factory.getCommentSectionIndex()
        let commentSectionRect = factory.getCommentSectionRect()
        self.tableView.setContentOffset(CGPoint(x: 0, y: commentSectionRect.minY.rounded() - 2), animated: true)
//        self.tableView.scrollToRow(at: IndexPath(row: 0, section: commentSection), at: .top, animated: true)
    }

    private func isCommentsScrolledToTop() -> Bool {
        guard let commentSectionIndex = factory?.getCommentSectionIndex(),
              let commentSectionRect = factory?.getCommentSectionRect() else {
            return true
        }
        let rectOfFirstComment = tableView.rectForRow(at: IndexPath(row: 0, section: commentSectionIndex))
        let rectRelativeToSuperview = tableView.convert(commentSectionRect, to: tableView.superview)
        let contentOffset = tableView.contentOffset.y
        return contentOffset == commentSectionRect.minY.rounded() - 2 ? true : false
    }

    @objc func keyboardWillAppear() {
        if keyboardAccessoryView.isEditing {
            self.keyboardAccessoryView.intrinsicHeight = keyboardAccessoryView.accessoryViewHeight
        }
    }

    @objc func keyboardWillDisappear() {
        print("keyboardWillDisappear triggered")
        self.keyboardAccessoryView.intrinsicHeight = keyboardAccessoryView.accessoryViewHeight + view.safeAreaInsets.bottom
    }
}

extension CommentsViewController {

    func setupFactory() {
        let post = viewModel.getPostViewModel()
        let comments = viewModel.getComments()
        self.factory = CommentListFactory(
            post: post,
            comments: comments,
            shouldShowRelatedPost: viewModel.shouldShowRelatedPost,
            tableView: self.tableView,
            delegate: self)
        self.factory?.registerCells()
    }

    func setupDataSource() {
        guard let sections = factory?.buildSections() else {
            return
        }
        let dataSource = DefaultTableViewDataSource(sections: sections)
        dataSource.delegate = self
        self.dataSource = dataSource
        self.tableView.dataSource = dataSource
        self.tableView.delegate = dataSource
    }
}

extension CommentsViewController: CommentAccessoryViewProtocol {
    func postButtonTapped(commentText: String, completion: @escaping () -> Void) {
        viewModel.postComment(commentText: commentText) { newlyCreatedComment in
            self.viewModel.insertNewlyCreatedComment(comment: newlyCreatedComment)
            if self.isCommentsScrolledToTop() {
                self.showCreatedCommentIfNeeded()
            } else {
                self.scrollToFirstRow()
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
        focusOnCommentIfNeeded()
        showCreatedCommentIfNeeded()
    }

    func didCommit(editingStyle: UITableViewCell.EditingStyle, at indexPath: IndexPath) {
        if editingStyle == .delete {
            viewModel.deleteComment(at: indexPath) {
                self.factory?.removeCommentCell(at: indexPath, with: .automatic)
            }
        }
    }
}
