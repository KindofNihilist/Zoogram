//
//  File.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 17.05.2023.
//

import UIKit

protocol CommentsTableViewActionsProtocol: PostTableViewCellProtocol, CommentCellProtocol {}

class PostWithCommentsViewController: UIViewController {

    let viewModel: PostWithCommentsViewModel

    private(set) var factory: CommentListFactory?

    private(set) var dataSource: TableViewDataSource?

    private var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(CommentTableViewCell.self, forCellReuseIdentifier: CommentTableViewCell.identifier)
        tableView.register(PostTableViewCell.self, forCellReuseIdentifier: PostTableViewCell.identifier)
        tableView.keyboardDismissMode = .interactive
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
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

    init(post: UserPost?, caption: CommentViewModel? = nil, commentIDToFocusOn: String? = nil, service: PostWithCommentsService) {
        self.viewModel = PostWithCommentsViewModel(
            post: post,
            caption: caption,
            commentIDToFocusOn: commentIDToFocusOn,
            service: service)
        super.init(nibName: nil, bundle: nil)
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillLayoutSubviews() {
        keyboardAccessoryView.intrinsicHeight = keyboardAccessoryView.accessoryViewHeight + view.safeAreaInsets.bottom
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view = tableView
        self.viewModel.hasInitialzied.bind { hasIntialized in
            if hasIntialized {
                self.tableView.reloadData()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        observeKeyboardEvents()
    }

    override func viewDidAppear(_ animated: Bool) {
        scrollToSelectedCommentIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    private func observeKeyboardEvents() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func scrollToSelectedCommentIfNeeded() {
        if let indexPath = viewModel.indexPathOfCommentToToFocusOn {
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
//        cell?.backgroundColor = ColorScheme.unseenEventLightBlue

        UIView.animate(withDuration: 0.5) {
            cell?.backgroundColor = ColorScheme.unseenEventLightBlue
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                cell?.backgroundColor = .systemBackground
            }
            self.viewModel.hasAlreadyFocusedOnComment = true
        }
    }

    func scrollToFirstRow() {
        let commentSection = viewModel.getCommentSection()
        self.tableView.scrollToRow(at: IndexPath(row: 0, section: commentSection), at: .top, animated: true)
    }

    @objc func keyboardWillAppear() {
        if keyboardAccessoryView.isEditing {
            self.keyboardAccessoryView.intrinsicHeight = keyboardAccessoryView.accessoryViewHeight
            scrollToFirstRow()
        }
    }

    @objc func keyboardWillDisappear() {
        print("keyboardWillDisappear triggered")
        self.keyboardAccessoryView.intrinsicHeight = keyboardAccessoryView.accessoryViewHeight + view.safeAreaInsets.bottom
    }
}

extension PostWithCommentsViewController {

    func setupFactory() {
        let caption = viewModel.getPostCaption()
        let post = viewModel.getPostViewModel()
        let comments = viewModel.getComments()
        self.factory = CommentListFactory(
            caption: caption,
            post: post,
            comments: comments,
            delegate: self)
    }

    func setupDataSource() {
        guard let sections = factory?.buildSections() else {
            return
        }
        self.dataSource = DefaultTableViewDataSource(sections: sections)
    }
}

extension PostWithCommentsViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getNumberOfRowsIn(section: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell: PostTableViewCell = tableView.dequeue(withIdentifier: PostTableViewCell.identifier, for: indexPath)
            let postVM = viewModel.getPostViewModel()
            cell.delegate = self
            cell.configure(with: postVM)
            return cell
        } else {
            let cell: CommentTableViewCell = tableView.dequeue(withIdentifier: CommentTableViewCell.identifier, for: indexPath)
            let commentVM = viewModel.getComment(for: indexPath)
            cell.delegate = self
            cell.configure(with: commentVM)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.section == 1 else {
            return false
        }
        let post = viewModel.getPostViewModel()
        let authorID = post.author.userID

        if authorID == AuthenticationManager.shared.getCurrentUserUID() {
            return true
        } else {
            return false
        }
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        guard indexPath.section == 1 else {
            return .none
        }
        return .delete
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else {
            return
        }

        if editingStyle == .delete {
            viewModel.deleteComment(at: indexPath) {
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.endUpdates()
            }
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        focusOnCommentIfNeeded()
    }

}

extension PostWithCommentsViewController: CommentAccessoryViewProtocol {
    func postButtonTapped(commentText: String, completion: @escaping () -> Void) {
        viewModel.postComment(commentText: commentText) {
            self.tableView.reloadData()
            self.scrollToFirstRow()
            completion()
        }
    }


}

extension PostWithCommentsViewController: CommentsTableViewActionsProtocol {

    func openUserProfile(of commentAuthor: ZoogramUser) {
        self.showProfile(of: commentAuthor)
    }

    func menuButtonTapped(cell: PostTableViewCell) {
        guard let postVM = viewModel.getPostViewModel() else {
            return
        }
        showMenuForPost(postViewModel: postVM, onDelete: {
            self.viewModel.deleteThisPost {
                sendNotificationToUpdateUserProfile()
                sendNotificationToUpdateUserFeed()
                self.navigationController?.popViewController(animated: true)
            }
        })
    }

    func didTapPostAuthor(cell: PostTableViewCell) {
        guard let postVM = viewModel.getPostViewModel() else {
            return
        }
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
