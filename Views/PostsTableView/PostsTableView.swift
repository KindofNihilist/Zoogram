//
//  PostsTableView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.12.2022.
//

import UIKit
import SDWebImage

@MainActor protocol PostsTableViewProtocol: AnyObject {
    func didTapCommentButton(viewModel: PostViewModel)
    func didSelectUser(user: ZoogramUser)
    func didTapMenuButton(postModel: PostViewModel, indexPath: IndexPath)
    func showLoadingError(_ error: Error)
}

typealias ScrollViewOffset = CGFloat
typealias ScrollViewPreviousOffset = CGFloat

class PostsTableView: UITableView {

    private let viewModel: PostsTableViewViewModel

    var tasks = [Task<Void, Never>?]()

    weak var postsTableDelegate: PostsTableViewProtocol?
    var didScrollAction: ((ScrollViewOffset, ScrollViewPreviousOffset) -> Void)?
    var didEndScrollingAction: (() -> Void)?

    private var previousScrollOffset: CGFloat = 0
    private var noPostsNotificationView: PlaceholderView?
    private var feedRefreshControl: UIRefreshControl?

    init(service: any PostsNetworking, posts: [PostViewModel] = [PostViewModel](), style: UITableView.Style = .plain) {
        self.viewModel = PostsTableViewViewModel(service: service, posts: posts)
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

    func getRetrievedPosts() -> [PostViewModel] {
        return viewModel.posts
    }

    @objc func getPosts() {
        let task = Task {
            do {
                try await viewModel.getPosts()
                if viewModel.posts.isEmpty {
                    self.showNoPostsNotificationIfNeeded()
                } else {
                    self.reloadData()
                    self.removeNoPostsNotificationIfDisplayed()
                    if await self.viewModel.hasHitTheEndOfPosts() {
                        self.removePaginationFooter()
                    } else {
                        self.showPaginationFooter()
                    }
                }
            } catch {
                self.postsTableDelegate?.showLoadingError(error)
            }
            self.feedRefreshControl?.endRefreshing()
        }
        tasks.append(task)
    }

    @objc private func getMorePosts() {
        let task = Task {
            guard await viewModel.isPaginationAllowed() else { return }
            do {
                if let paginatedPosts = try await viewModel.getMorePosts() {
                    let postsCountBeforeUpdate = self.viewModel.posts.count
                    self.viewModel.posts.append(contentsOf: paginatedPosts)
                    let postsCountAfterUpdate = self.viewModel.posts.count
                    let indexPathsOfPaginatedPosts = (postsCountBeforeUpdate ..< postsCountAfterUpdate).map {
                        IndexPath(row: $0, section: 0)
                    }
                    self.insertRows(at: indexPathsOfPaginatedPosts, with: .fade)
                }
            } catch {
                self.showPaginationErrorView(for: error)
            }
            self.setupLoadingIndicatorFooter()
        }
        tasks.append(task)
    }

    func setPostsViewModels(postsViewModels: [PostViewModel]) {
        self.viewModel.posts = postsViewModels
    }

    func insertPlaceholderCell() {
        let blankViewModel = PostViewModel.createPlaceholderViewModel()
        self.viewModel.posts.insert(blankViewModel, at: 0)
        let indexPath = IndexPath(row: 0, section: 0)
        self.insertRows(at: [indexPath], with: .top)
    }

    func removePlaceholderCell() {
        guard viewModel.posts[0].shouldDisplayAsPlaceholder == true else { return }
        self.viewModel.posts.remove(at: 0)
        let indexPath = IndexPath(row: 0, section: 0)
        self.deleteRows(at: [indexPath], with: .automatic)
    }

    func replaceBlankCellWithNewlyCreatedPost(postViewModel: PostViewModel) {
        self.viewModel.posts[0] = postViewModel
        let indexPath = [IndexPath(row: 0, section: 0)]
        self.reloadRows(at: indexPath, with: .none)
    }

    func deletePost(at indexPath: IndexPath, completion: @escaping (VoidResult) -> Void) {
        let task = Task {
            do {
                try await viewModel.deletePost(at: indexPath)
                self.deleteRows(at: [indexPath], with: .fade)
                completion(.success)
            } catch {
                completion(.failure(error))
            }
        }
        tasks.append(task)
    }

    func makeNewlyCreatedPostVisible(at indexPath: IndexPath, completion: @escaping () -> Void) {
        guard let cell = self.cellForRow(at: indexPath) as? PostTableViewCell else {
            return
        }
        cell.makePostVisible {
            self.viewModel.posts[indexPath.row].changeIsNewlyCreatedStatus(to: false)
            completion()
        }
    }

    private func setupRefreshControl() {
        feedRefreshControl = UIRefreshControl()
        feedRefreshControl?.addTarget(self, action: #selector(getPosts), for: .valueChanged)
        self.refreshControl = feedRefreshControl
    }

    func setupLoadingIndicatorFooter() {
        let task = Task {
            let hasHitTheEndOfPosts = await viewModel.hasHitTheEndOfPosts()
            print("hasHitEndOfPosts: \(hasHitTheEndOfPosts)")
            if hasHitTheEndOfPosts == false {
                self.showPaginationFooter()
            } else {
                self.removePaginationFooter()
            }
        }
        tasks.append(task)
    }

    private func showPaginationFooter() {
        guard viewModel.posts.isEmpty != true else { return }
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 200))
        let spinner = UIActivityIndicatorView(style: .medium)
        footerView.addSubview(spinner)
        spinner.center = footerView.center
        spinner.startAnimating()
        self.tableFooterView = footerView
    }

    private func removePaginationFooter() {
        self.tableFooterView = nil
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
        guard self.noPostsNotificationView == nil && self.viewModel.posts.isEmpty else { return }
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
}

extension PostsTableView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let postViewModel = viewModel.posts[indexPath.row]
        if postViewModel.shouldDisplayAsPlaceholder {
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
        let contentYOffset = scrollView.contentOffset.y
        didScrollAction?(contentYOffset, previousScrollOffset)
        previousScrollOffset = contentYOffset
        guard contentYOffset > 0 else { return }
        let contentHeight = self.contentSize.height
        let tableViewHeight = self.frame.size.height
        if contentYOffset > (contentHeight - tableViewHeight - 100) {
            self.getMorePosts()
        }
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
        let postViewModel = self.viewModel.posts[indexPath.row]
        postsTableDelegate?.didTapMenuButton(postModel: postViewModel, indexPath: indexPath)
    }

    func didTapPostAuthor(cell: PostTableViewCell) {
        guard let indexPath = self.indexPath(for: cell) else {
            return
        }
        let postAuthor = viewModel.posts[indexPath.row].author
        postsTableDelegate?.didSelectUser(user: postAuthor)
    }

    func didTapLikeButton(cell: PostTableViewCell) async throws {
        guard let indexPath = self.indexPath(for: cell) else { return }
        let task = Task {
            do {
                try await viewModel.likePost(at: indexPath)
            } catch {
                print("Error while liking a post")
            }
        }
        tasks.append(task)
    }

    func didTapCommentButton(cell: PostTableViewCell) {
        guard let indexPath = self.indexPath(for: cell) else {
            return
        }
        let postViewModel = self.viewModel.posts[indexPath.row]
        postsTableDelegate?.didTapCommentButton(viewModel: postViewModel)
    }

    func didTapBookmarkButton(cell: PostTableViewCell) async throws {
        guard let indexPath = self.indexPath(for: cell) else { return }
        let task = Task {
            do {
                try await viewModel.bookmarkPost(at: indexPath)
            } catch {
                print("Error while bookmarking a post")
            }
        }
        tasks.append(task)
    }
}

extension PostsTableView: LoadingErrorViewDelegate {
    func didTapReloadButton() {
        showPaginationFooter()
        getMorePosts()
    }
}
