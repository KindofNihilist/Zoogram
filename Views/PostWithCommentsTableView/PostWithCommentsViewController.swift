//
//  File.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 17.05.2023.
//

import UIKit

class PostWithCommentsViewController: UIViewController {

    let viewModel: PostWithCommentsViewModel

    private var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(PostCommentTableViewCell.self, forCellReuseIdentifier: PostCommentTableViewCell.identifier)
        tableView.register(PostTableViewCell.self, forCellReuseIdentifier: PostTableViewCell.identifier)
        tableView.keyboardDismissMode = .interactive
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        return tableView
    }()

    init(post: UserPost, service: PostWithCommentsService) {
        self.viewModel = PostWithCommentsViewModel(post: post, service: service)
        super.init(nibName: nil, bundle: nil)
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            let cell: PostCommentTableViewCell = tableView.dequeue(withIdentifier: PostCommentTableViewCell.identifier, for: indexPath)
            let commentVM = viewModel.getComment(for: indexPath)
            cell.configure(with: commentVM)
            return cell
        }
    }

}

extension PostWithCommentsViewController: PostTableViewCellProtocol {

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
