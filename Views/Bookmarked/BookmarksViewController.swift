//
//  BookmarksTableView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 06.03.2023.
//

import UIKit

class BookmarksViewController: UIViewController {

    private var viewModel: BookmarksViewModel
    private var factory: BookmarksFactory!
    private var dataSource: DefaultCollectionViewDataSource!

    private var task: Task<Void, Error>?

    private var postsTableViewController: PostsTableViewController!
    private var bookmarksRefreshControl: UIRefreshControl?

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .vertical
        layout.sectionInsetReference = .fromSafeArea
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = Colors.background
        return collectionView
    }()

    private lazy var noBookmarksView: UIView = {
        let text = String(localized: "Bookmarked posts will be displayed here")
        let noBookmarksView = PlaceholderView(imageName: "bookmark.fill", text: text)
        noBookmarksView.translatesAutoresizingMaskIntoConstraints = false
        return noBookmarksView
    }()

    private lazy var loadingErrorView: LoadingErrorView = {
        let loadingErrorView = LoadingErrorView()
        loadingErrorView.translatesAutoresizingMaskIntoConstraints = false
        return loadingErrorView
    }()

    init(service: any BookmarkedPostsServiceProtocol) {
        self.viewModel = BookmarksViewModel(service: service)
        super.init(nibName: nil, bundle: nil)
        postsTableViewController = PostsTableViewController(posts: [], service: service)
        factory = BookmarksFactory(for: collectionView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = String(localized: "Bookmarks")
        setupCollectionView()
        setupRefreshControl()
        view.backgroundColor = Colors.background
        postsTableViewController.updateTableViewFrame(to: self.view.frame)
        postsTableViewController.delegate = self
        postsTableViewController.title = self.title
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        if self.isBeingPresented || self.isMovingToParent {
            collectionView.refreshControl?.beginRefreshingManually()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        task?.cancel()
    }

    private func setupCollectionView() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupRefreshControl() {
        bookmarksRefreshControl = UIRefreshControl()
        bookmarksRefreshControl?.addTarget(self, action: #selector(getBookmarks), for: .valueChanged)
        collectionView.refreshControl = bookmarksRefreshControl
    }

    private func setupFactory() {
        self.factory.buildSections(for: viewModel.bookmarks)
        self.dataSource = DefaultCollectionViewDataSource(sections: factory.sections)
        self.dataSource.delegate = self
        self.collectionView.dataSource = self.dataSource
        self.collectionView.delegate = self.dataSource
        self.factory.postCellAction = { indexPath in
            self.postSelectAction(at: indexPath)
        }
        self.collectionView.reloadData()
    }

    @objc private func getBookmarks() {
        task = Task {
            do {
                if let bookmarks = try await viewModel.getBookmarks() {
                    self.updateBookmarksTableView(with: bookmarks)
                    self.setupFactory()
                    self.hideLoadingFooterIfNeeded()
                    self.removeNoPostsView()
                } else {
                    self.createNoPostsView()
                }
                self.collectionView.refreshControl?.endRefreshing()
            } catch {
                self.handleLoadingError(error: error)
            }
        }
    }

    private func getMoreBookmarks() {
        task = Task {
            guard await viewModel.isPaginationAllowed() else { return }
            factory.showLoadingIndicator()
            do {
                if let unwrappedBookmarks = try await viewModel.getMoreBookmarks() {
                    self.factory.updatePostsSection(with: unwrappedBookmarks) {
                        self.updateBookmarksTableView(with: self.viewModel.bookmarks)
                    }
                }
            } catch {
                self.factory.showPaginationRetryButton(error: error, delegate: self)
            }
            hideLoadingFooterIfNeeded()
        }
    }

    private func handleLoadingError(error: Error) {
        Task {
            let hasLoadedData = await viewModel.checkIfHasLoadedData()
            if hasLoadedData {
                self.showPopUp(issueText: error.localizedDescription)
            } else {
                self.showReloadButton(with: error)
            }
            self.collectionView.refreshControl?.endRefreshing()
        }
    }

    private func updateBookmarksTableView(with bookmarks: [Bookmark]) {
        let posts = bookmarks.compactMap { $0.getPostViewModel() }
        self.postsTableViewController.updatePostsArrayWith(posts: posts)
    }

    private func postSelectAction(at indexPath: IndexPath) {
        guard viewModel.bookmarks.isEmpty != true else { return }
        self.postsTableViewController.focusTableViewOnPostWith(index: indexPath)
        if #available(iOS 18.0, *) {
            self.postsTableViewController.preferredTransition = .zoom { context in
                let postsTableView = context.zoomedViewController as! PostsTableViewController
                let lastSeenPostIndexPath = postsTableView.getLastVisibleCellIndexPath() ?? indexPath
                return self.collectionView.cell(at: lastSeenPostIndexPath)
            }
        }
        self.navigationController?.pushViewController(self.postsTableViewController, animated: true)
    }

    private func createNoPostsView() {
        collectionView.addSubview(noBookmarksView)
        NSLayoutConstraint.activate([
            noBookmarksView.topAnchor.constraint(greaterThanOrEqualTo: collectionView.topAnchor, constant: 150),
            noBookmarksView.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            noBookmarksView.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor, constant: -40),
            noBookmarksView.heightAnchor.constraint(equalToConstant: 200),
            noBookmarksView.widthAnchor.constraint(equalTo: collectionView.widthAnchor)
        ])
    }

    private func removeNoPostsView() {
        noBookmarksView.removeFromSuperview()
    }

    private func hideLoadingFooterIfNeeded() {
        Task {
            let hasHitTheEndOfBookmarks = await viewModel.hasHitTheEndOfBookmarks()
            if hasHitTheEndOfBookmarks {
                self.factory.hideLoadingFooter()
            } else {
                self.factory.showLoadingIndicator()
            }
        }
    }

    private func showReloadButton(with error: Error) {
        view.addSubview(loadingErrorView)
        loadingErrorView.alpha = 1
        NSLayoutConstraint.activate([
            loadingErrorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingErrorView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            loadingErrorView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -60),
            loadingErrorView.heightAnchor.constraint(equalToConstant: 80)
        ])
        loadingErrorView.setDescriptionLabelText(error.localizedDescription)
        loadingErrorView.delegate = self
    }

    private func hideReloadButton() {
        UIView.animate(withDuration: 0.3) {
            self.loadingErrorView.alpha = 0
        } completion: { _ in
            self.loadingErrorView.removeFromSuperview()
        }
    }
}

extension BookmarksViewController: PostsTableViewDelegate {
    func updateCollectionView(with postViewModels: [PostViewModel]) {
        guard self.viewModel.bookmarks.count < postViewModels.count else {
            return
        }
        let bookmarks = postViewModels.map { viewModel in
            var bookmark = Bookmark(postID: viewModel.postID, postAuthorID: viewModel.author.userID)
            bookmark.associatedPost = viewModel
            return bookmark
        }
        self.viewModel.bookmarks = bookmarks
        self.factory.refreshPostsSection(with: bookmarks)
        self.hideLoadingFooterIfNeeded()
    }

    func lastVisibleItem(at indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return }
        self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
    }
}

extension BookmarksViewController: CollectionViewDataSourceDelegate {

    func scrollViewDidScroll(scrollView: UIScrollView) {
        let position = scrollView.contentOffset.y
        let contentHeight = collectionView.contentSize.height
        let scrollViewHeight = scrollView.frame.size.height
        guard position > 0 else { return }
        if position > (contentHeight - scrollViewHeight - 100) {
            self.getMoreBookmarks()
        }
    }
}

extension BookmarksViewController: LoadingErrorViewDelegate {
    func didTapReloadButton() {
        hideReloadButton()
        collectionView.refreshControl?.beginRefreshingManually()
    }
}

extension BookmarksViewController: PaginationIndicatorCellDelegate {
    func didTapRetryPaginationButton() {
        factory.showLoadingIndicator()
        getMoreBookmarks()
    }
}
