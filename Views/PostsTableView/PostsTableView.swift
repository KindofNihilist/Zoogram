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
    func showLoadingError(_ error: Error)
}

typealias ScrollViewOffset = CGFloat
typealias ScrollViewPreviousOffset = CGFloat

class PostsTableView: UITableView {

    private var service: any PostsNetworking

    weak var postsTableDelegate: PostsTableViewProtocol?

    var posts = [PostViewModel]()

    var didScrollAction: ((ScrollViewOffset, ScrollViewPreviousOffset) -> Void)?
    var didEndScrollingAction: (() -> Void)?
    private var previousScrollOffset: CGFloat = 0
    var isPaginationAllowed: Bool = true
    private var noPostsNotificationView: PlaceholderView?
    private var feedRefreshControl: UIRefreshControl?

    init(service: any PostsNetworking, posts: [PostViewModel] = [PostViewModel](), style: UITableView.Style = .plain) {
        self.service = service
        super.init(frame: CGRect.zero, style: style)
        register(PostTableViewCell.self, forCellReuseIdentifier: PostTableViewCell.identifier)
        register(NewPostPlaceholderTableViewCell.self, forCellReuseIdentifier: NewPostPlaceholderTableViewCell.identifier)
        allowsSelection = false
        separatorStyle = .none
        rowHeight = UITableView.automaticDimension
        estimatedRowHeight = 0
        showsVerticalScrollIndicator = false
        backgroundColor = Colors.background
        self.dataSource = self
        self.delegate = self
        setupRefreshControl()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func getPosts() {
        service.getItems { posts, error in
            if let error = error {
                self.postsTableDelegate?.showLoadingError(error)
            } else if let posts = posts {
                self.posts = posts.compactMap({ provider in
                    return provider.getPostViewModel()
                })
                self.removeNoPostsNotificationIfDisplayed()
                if self.service.hasHitTheEndOfPosts {
                    self.removePaginationFooterIfNeeded()
                } else {
                    self.setupLoadingIndicatorFooter()
                }
                self.reloadData()
            } else {
                self.showNoPostsNotificationIfNeeded()
            }
            self.feedRefreshControl?.endRefreshing()
        }
    }

    @objc func getMorePosts() {
        self.showFooterLoadingView()
        self.service.getMoreItems { posts, error in
            if let error = error {
                self.showPaginationErrorView(for: error)
                return
            } else if let posts {
                let postViewModels = posts.compactMap({ provider in
                    return provider.getPostViewModel()
                })
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    let postsCountBeforeUpdate = self.posts.count
                    self.posts.append(contentsOf: postViewModels)
                    let indexPaths = (postsCountBeforeUpdate ..< self.posts.count).map {
                        IndexPath(row: $0, section: 0)
                    }
                    self.insertRows(at: indexPaths, with: .fade)
                    self.service.isAlreadyPaginating = false
                }
            }
            self.removePaginationFooterIfNeeded()
        }
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

    func removeBlankCell() {
        guard posts[0].shouldShowBlankCell == true else { return }
        self.posts.remove(at: 0)
        let indexPath = IndexPath(row: 0, section: 0)
        self.deleteRows(at: [indexPath], with: .automatic)
    }

    func replaceBlankCellWithNewlyCreatedPost(postViewModel: PostViewModel) {
        self.posts[0] = postViewModel
        let indexPath = [IndexPath(row: 0, section: 0)]
        self.reloadRows(at: indexPath, with: .none)
    }

    func deletePost(at indexPath: IndexPath, completion: @escaping (VoidResult) -> Void) {
        let postModel = posts[indexPath.row]
        self.service.deletePost(postModel: postModel) { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success:
                strongSelf.posts.remove(at: indexPath.row)
                strongSelf.deleteRows(at: [indexPath], with: .fade)
                completion(.success)
            case .failure(let error):
                completion(.failure(error))
            }

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

    private func setupRefreshControl() {
        feedRefreshControl = UIRefreshControl()
        feedRefreshControl?.addTarget(self, action: #selector(getPosts), for: .valueChanged)
        self.refreshControl = feedRefreshControl
    }

    func setupLoadingIndicatorFooter() {
        guard service.hasHitTheEndOfPosts != true && self.isPaginationAllowed else {
            self.tableFooterView = nil
            return
        }
        showFooterLoadingView()
    }

    private func showFooterLoadingView() {
        guard posts.isEmpty != true else {
            return
        }
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 200))
        let spinner = UIActivityIndicatorView(style: .medium)
        footerView.addSubview(spinner)
        spinner.center = footerView.center
        spinner.startAnimating()
        self.tableFooterView = footerView
    }

    private func removePaginationFooterIfNeeded() {
        if self.isPaginationAllowed == false || service.hasHitTheEndOfPosts {
            self.tableFooterView = nil
        }
    }

    private func showPaginationErrorView(for error: Error) {
        let paginationErrorView = LoadingErrorView(
            frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 200),
            reloadButtonSize: CGSize(width: 25, height: 25))
        paginationErrorView.descriptionLabel.font = CustomFonts.boldFont(ofSize: 14)
        paginationErrorView.delegate = self
        paginationErrorView.setDescriptionLabelText(error.localizedDescription)
        self.tableFooterView = paginationErrorView
    }

    func showNoPostsNotificationIfNeeded() {
        guard self.noPostsNotificationView ==  nil && self.posts.isEmpty else { return }
        let notificationText = String(localized: "New posts of people you follow will be displayed here")
        noPostsNotificationView = PlaceholderView(imageName: "camera",
                                                  text: notificationText)
        noPostsNotificationView?.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(noPostsNotificationView!)
        NSLayoutConstraint.activate([
            noPostsNotificationView!.heightAnchor.constraint(equalToConstant: 250),
            noPostsNotificationView!.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            noPostsNotificationView!.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -25),
            noPostsNotificationView!.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -40)
        ])
    }

    func removeNoPostsNotificationIfDisplayed() {
        if noPostsNotificationView != nil {
            noPostsNotificationView?.removeFromSuperview()
            noPostsNotificationView = nil
        }
    }

    private func paginateMorePosts(contentOffset: CGFloat) {
        guard service.hasHitTheEndOfPosts != true && self.isPaginationAllowed else {
            return
        }

        let contentHeight = self.contentSize.height
        let tableViewHeight = self.frame.size.height

        if contentOffset > (contentHeight - tableViewHeight - 100) {
            self.getMorePosts()
        }
    }
}

extension PostsTableView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let postViewModel = posts[indexPath.row]
        if postViewModel.shouldShowBlankCell {
            let cell: NewPostPlaceholderTableViewCell = tableView.dequeue(withIdentifier: NewPostPlaceholderTableViewCell.identifier, for: indexPath)
            return cell
        } else {
            let cell: PostTableViewCell = tableView.dequeue(withIdentifier: PostTableViewCell.identifier, for: indexPath)
            cell.delegate = self
            cell.configure(with: postViewModel)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScrollAction?(scrollView.contentOffset.y, previousScrollOffset)
        previousScrollOffset = scrollView.contentOffset.y
        paginateMorePosts(contentOffset: scrollView.contentOffset.y)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        didEndScrollingAction?()
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

    func didTapLikeButton(cell: PostTableViewCell, completion: @escaping (Result<LikeState, Error>) -> Void) {
        guard let indexPath = self.indexPath(for: cell) else {
            return
        }
        let postViewModel = self.posts[indexPath.row]
        self.service.likePost(postID: postViewModel.postID,
                              likeState: postViewModel.likeState,
                              postAuthorID: postViewModel.author.userID) { result in
            switch result {
            case .success(let likeState):
                postViewModel.likeState = likeState
                cell.setLikesTitle(title: postViewModel.likesCountTitle)
                completion(.success(likeState))
            case .failure(let error):
                completion(.failure(error))
            }

        }
    }

    func didTapCommentButton(cell: PostTableViewCell) {
        guard let indexPath = self.indexPath(for: cell) else {
            return
        }
        let postViewModel = self.posts[indexPath.row]
        postsTableDelegate?.didTapCommentButton(viewModel: postViewModel)
    }

    func didTapBookmarkButton(cell: PostTableViewCell, completion: @escaping (Result<BookmarkState, Error>) -> Void) {
        guard let indexPath = self.indexPath(for: cell) else {
            return
        }
        let postViewModel = self.posts[indexPath.row]
        self.service.bookmarkPost(postID: postViewModel.postID,
                                  authorID: postViewModel.author.userID,
                                  bookmarkState: postViewModel.bookmarkState) { result in
            switch result {
            case .success(let bookmarkState):
                self.posts[indexPath.row].bookmarkState = bookmarkState
                completion(.success(bookmarkState))
            case .failure(let error):
                completion(.failure(error))
            }

        }
    }
}

extension PostsTableView: LoadingErrorViewDelegate {
    func didTapReloadButton() {
        showFooterLoadingView()
        getMorePosts()
    }
}
