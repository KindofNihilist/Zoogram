//
//  PostsTableView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.12.2022.
//

import UIKit
import SDWebImage

protocol PostsTableViewProtocol: AnyObject {
    func didTapCommentButton(viewModel: PostViewModel)
    func didSelectUser(user: ZoogramUser)
    func didTapMenuButton(postModel: PostViewModel, indexPath: IndexPath)
}

class PostsTableView: UITableView {

    var posts = [PostViewModel]()

    var service: PostsService!

    var noPostsNotificationView: PlaceholderView?

    var isPaginationAllowed: Bool = true

    weak var postsTableDelegate: PostsTableViewProtocol?

    var feedRefreshControl: UIRefreshControl?

    convenience init(service: PostsService, posts: [PostViewModel] = [PostViewModel]()) {
        self.init(frame: CGRect.zero)
        self.posts = posts
        self.service = service
    }

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        register(PostTableViewCell.self, forCellReuseIdentifier: PostTableViewCell.identifier)
        allowsSelection = false
        separatorStyle = .none
        rowHeight = UITableView.automaticDimension
        estimatedRowHeight = 0
        showsVerticalScrollIndicator = false
        self.dataSource = self
        self.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setUserPostsViewModels(postsViewModels: [PostViewModel]) {
        self.posts = postsViewModels
        self.reloadData()
    }

    func insertBlankCell() {
        let blankViewModel = PostViewModel.createBlankViewModel()
        self.posts.insert(blankViewModel, at: 0)
        let indexPath = IndexPath(row: 0, section: 0)
        self.insertRows(at: [indexPath], with: .top)
    }

    func replaceBlankCellWithNewlyCreatedPost(postViewModel: PostViewModel) {
        self.posts[0] = postViewModel
        self.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .top)
    }

    func deletePost(at indexPath: IndexPath, completion: @escaping () -> Void) {
        let postModel = posts[indexPath.row]
        self.service.deletePost(postModel: postModel) { [weak self] in
            self?.posts.remove(at: indexPath.row)
            self?.deleteRows(at: [indexPath], with: .fade)
            completion()
        }
    }

    func makeNewlyCreatedPostVisible(at indexPath: IndexPath, completion: @escaping () -> Void) {
        guard let cell = self.cellForRow(at: indexPath) as? PostTableViewCell else {
            return
        }
        cell.makePostVisible {
            self.posts[indexPath.row].isNewlyCreated = false
            completion()
        }
    }

    func setupRefreshControl() {
        feedRefreshControl = UIRefreshControl()
        feedRefreshControl?.addTarget(self, action: #selector(refreshUserFeed), for: .valueChanged)
        self.refreshControl = feedRefreshControl
        refreshControl?.beginRefreshing()
    }

    private func createFooterSpinnerView() -> UIView {
        guard posts.isEmpty != true else {
            return UIView()
        }
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 200))
        let spinner = UIActivityIndicatorView(style: .medium)
        footerView.addSubview(spinner)
        spinner.center = footerView.center
        spinner.startAnimating()
        return footerView
    }

    private func showNoPostsNotification() {
        noPostsNotificationView = PlaceholderView(imageName: "camera",
                                                  text: "New posts of people you follow will be displayed here")
        noPostsNotificationView?.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(noPostsNotificationView!)
        NSLayoutConstraint.activate([
            noPostsNotificationView!.heightAnchor.constraint(equalToConstant: 250),
            noPostsNotificationView!.widthAnchor.constraint(equalTo: self.widthAnchor),
            noPostsNotificationView!.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -20)
        ])
    }

    private func removeNoPostsNotificationIfDisplayed() {
        if noPostsNotificationView != nil {
            noPostsNotificationView?.removeFromSuperview()
        }
    }

    @objc func refreshUserFeed() {
        service.getPosts { posts in
            guard posts.isEmpty != true else {
                self.posts = posts
                self.reloadData()
                self.refreshControl?.endRefreshing()
                self.showNoPostsNotification()
                return
            }
            self.posts = posts
            self.refreshControl?.endRefreshing()
            self.removeNoPostsNotificationIfDisplayed()
            self.reloadData()
        }
    }
}

extension PostsTableView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PostTableViewCell = tableView.dequeue(withIdentifier: PostTableViewCell.identifier, for: indexPath)
        let post = posts[indexPath.row]
        cell.delegate = self
        cell.configure(with: post)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard service.hasHitTheEndOfPosts != true && self.isPaginationAllowed else {
            UIView.animate(withDuration: 0.6) {
                self.tableFooterView?.alpha = 0
            } completion: { _ in
                self.tableFooterView = nil
            }
            return
        }
        let position = scrollView.contentOffset.y

        if position > (self.contentSize.height - 100 - scrollView.frame.size.height) {
            self.tableFooterView = createFooterSpinnerView()
            self.service.getMorePosts { retrievedPosts in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    if let unwrapedPosts = retrievedPosts {
                        let postsCountBeforeUpdate = self.posts.count
                        self.posts.append(contentsOf: unwrapedPosts)
                        let indexPaths = (postsCountBeforeUpdate ..< self.posts.count).map {
                            IndexPath(row: $0, section: 0)
                        }
                        self.insertRows(at: indexPaths, with: .fade)
                        self.service.isAlreadyPaginating = false
                    }
                }
            }
        }
    }
}

extension PostsTableView: PostTableViewCellProtocol {
    func menuButtonTapped(cell: PostTableViewCell) {
        guard let indexPath = self.indexPath(for: cell) else {
            return
        }
        let postViewModel = self.posts[indexPath.row]
        postsTableDelegate?.didTapMenuButton(postModel: postViewModel, indexPath: indexPath)
    }

    func didTapPostAuthor(cell: PostTableViewCell) {
        guard let indexPath = self.indexPath(for: cell) else {
            return
        }
        let user = posts[indexPath.row].author
        postsTableDelegate?.didSelectUser(user: user)
    }

    func didTapLikeButton(cell: PostTableViewCell, completion: @escaping (LikeState) -> Void) {
        guard let indexPath = self.indexPath(for: cell) else {
            return
        }
        let postViewModel = self.posts[indexPath.row]
        self.service.likePost(postID: postViewModel.postID,
                              likeState: postViewModel.likeState,
                              postAuthorID: postViewModel.author.userID) { likeState in
            postViewModel.likeState = likeState
            cell.setLikesTitle(title: postViewModel.likesCountTitle)
            completion(likeState)
        }
    }

    func didTapCommentButton(cell: PostTableViewCell) {
        guard let indexPath = self.indexPath(for: cell) else {
            return
        }
        let postViewModel = self.posts[indexPath.row]
        postsTableDelegate?.didTapCommentButton(viewModel: postViewModel)
    }

    func didTapBookmarkButton(cell: PostTableViewCell, completion: @escaping (BookmarkState) -> Void) {
        guard let indexPath = self.indexPath(for: cell) else {
            return
        }
        let postViewModel = self.posts[indexPath.row]
        self.service.bookmarkPost(postID: postViewModel.postID,
                                  authorID: postViewModel.author.userID,
                                  bookmarkState: postViewModel.bookmarkState) { bookmarkState in
            self.posts[indexPath.row].bookmarkState = bookmarkState
            completion(bookmarkState)
        }
    }
}
