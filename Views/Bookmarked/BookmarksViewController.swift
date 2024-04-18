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
    }

    override func viewDidAppear(_ animated: Bool) {
        if self.isBeingPresented || self.isMovingToParent {
            collectionView.refreshControl?.beginRefreshingManually()
        }
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
        viewModel.getBookmarks { result in
            switch result {
            case .success(let bookmarks):
                if let unwrappedBookmarks = bookmarks {
                    self.updateBookmarksTableView(with: unwrappedBookmarks)
                    self.setupFactory()
                    self.hideLoadingFooterIfNeeded()
                    self.removeNoPostsView()
                } else {
                    self.createNoPostsView()
                }
                self.collectionView.refreshControl?.endRefreshing()
            case .failure(let error):
                self.handleLoadingError(error: error)
            }
        }
    }

    private func getMoreBookmarks() {
        factory.showLoadingIndicator()
        viewModel.getMoreBookmarks { result in
            switch result {
            case .success(let bookmarks):
                if let unwrappedBookmarks = bookmarks {
                    self.factory.updatePostsSection(with: unwrappedBookmarks) {
                        self.updateBookmarksTableView(with: self.viewModel.bookmarks)
                        self.viewModel.hasFinishedPagination()
                    }
                }
                self.hideLoadingFooterIfNeeded()
            case .failure(let error):
                self.factory.showPaginationRetryButton(error: error, delegate: self)
            }
        }
    }

    private func handleLoadingError(error: Error) {
        if viewModel.checkIfHasLoadedData() {
            self.showPopUp(issueText: error.localizedDescription)
        } else {
            self.showReloadButton(with: error)
        }
        self.collectionView.refreshControl?.endRefreshing()
    }

    private func updateBookmarksTableView(with bookmarks: [Bookmark]) {
        print("updating table view of bookmarks")
        let posts = bookmarks.compactMap { $0.getPostViewModel() }
        self.postsTableViewController.updatePostsArrayWith(posts: posts)
    }

    private func postSelectAction(at indexPath: IndexPath) {
        guard viewModel.bookmarks.isEmpty != true else {
            return
        }
        self.postsTableViewController.focusTableViewOnPostWith(index: indexPath)
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
        if viewModel.hasHitTheEndOfBookmarks() {
            self.factory.hideLoadingFooter()
        } else {
            self.factory.showLoadingIndicator()
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
            let bookmark = Bookmark(postID: viewModel.postID, postAuthorID: viewModel.author.userID)
            bookmark.associatedPost = viewModel
            return bookmark
        }
        self.viewModel.bookmarks = bookmarks
        self.factory.refreshPostsSection(with: bookmarks)
        self.hideLoadingFooterIfNeeded()
    }
}

extension BookmarksViewController: CollectionViewDataSourceDelegate {

    func scrollViewDidScroll(scrollView: UIScrollView) {
        guard viewModel.isPaginationAllowed() else {
            return
        }
        let position = scrollView.contentOffset.y
        let contentHeight = collectionView.contentSize.height
        let scrollViewHeight = scrollView.frame.size.height

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
