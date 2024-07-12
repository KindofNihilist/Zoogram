//
//  DiscoverViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//

import UIKit
import SDWebImage

class DiscoverViewController: UIViewController {

    let viewModel: DiscoverViewModel

    private var dataSource: CollectionViewDataSource?
    private var factory: DiscoverCollectionViewFactory!
    private var refreshControl: UIRefreshControl?

    private var tasks = [Task<Void, Never>?]()

    private var timer: Timer?

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: view.frame.width/3, height: view.frame.width/3)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    private var postsTableView: PostsTableViewController

    private let spinnerView: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.isHidden = true
        return spinner
    }()

    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.autocapitalizationType = .none
        searchBar.placeholder = String(localized: "Search users")
        searchBar.searchTextField.font = CustomFonts.regularFont(ofSize: 16)
        searchBar.returnKeyType = .search
        searchBar.searchBarStyle = .minimal
        searchBar.layer.cornerCurve = .continuous
        searchBar.layer.cornerRadius = 15
        searchBar.delegate = self
        searchBar.tintColor = Colors.label
        return searchBar
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(SearchedUserTableViewCell.self, forCellReuseIdentifier: SearchedUserTableViewCell.identifier)
        tableView.backgroundColor = Colors.background
        tableView.keyboardDismissMode = .interactive
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    private lazy var loadingErrorView: LoadingErrorView = {
        let loadingErrorView = LoadingErrorView()
        loadingErrorView.translatesAutoresizingMaskIntoConstraints = false
        return loadingErrorView
    }()

    init(service: any DiscoverServiceProtocol) {
        self.postsTableView = PostsTableViewController(posts: [], service: service)
        self.postsTableView.title = String(localized: "Latest")
        self.viewModel = DiscoverViewModel(service: service)
        super.init(nibName: nil, bundle: nil)
        self.postsTableView.delegate = self
        view.backgroundColor = Colors.background
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        postsTableView.updateTableViewFrame(to: self.view.frame)
        setupSearchBar()
        setupTableView()
        setupCollectionView()
        setupEdditingInteruptionGestures()
        setupRefreshControl()
        refreshControl?.beginRefreshingManually()
        viewModel.foundUsers.bind { _ in
            self.tableView.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tasks.forEach { task in
            task?.cancel()
        }
    }

    func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(getPosts), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }

    @objc private func getPosts() {
        loadingErrorView.removeFromSuperview()
        let task = Task {
            do {
                let retrievedPosts = try await viewModel.getPostsToDiscover()
                self.factory = DiscoverCollectionViewFactory(for: self.collectionView)
                self.postsTableView.updatePostsArrayWith(posts: retrievedPosts)
                self.refreshControl?.endRefreshing()
                self.setupDataSource()
            } catch {
                self.handleLoadingError(error: error)
            }
        }
        tasks.append(task)
    }

    private func setupDataSource() {
        factory.buildSections(for: viewModel.posts.value)
        let dataSource = DefaultCollectionViewDataSource(sections: factory.sections)
        dataSource.delegate = self
        self.dataSource = dataSource
        self.collectionView.delegate = dataSource
        self.collectionView.dataSource = dataSource
        factory.cellAction = { indexPath in
            self.showPost(at: indexPath)
        }
        self.collectionView.reloadData()
    }

    private func showPost(at indexPath: IndexPath) {
        guard self.viewModel.posts.value.isEmpty != true else { return }
        self.postsTableView.focusTableViewOnPostWith(index: indexPath)
        if #available(iOS 18.0, *) {
            self.postsTableView.preferredTransition = .zoom { context in
                let postsTableView = context.zoomedViewController as! PostsTableViewController
                let lastSeenPostIndexPath = postsTableView.getLastVisibleCellIndexPath() ?? indexPath
                return self.collectionView.cell(at: lastSeenPostIndexPath)
            }
        }
        self.navigationController?.pushViewController(self.postsTableView, animated: true)
    }

    private func showCollectionViewWithPosts() {
        self.collectionView.isHidden = false
        self.searchBar.setShowsCancelButton(false, animated: true)
        UIView.animate(withDuration: 0.2) {
            self.collectionView.alpha = 1
            self.tableView.alpha = 0
        } completion: { _ in
            self.tableView.isHidden = true
        }
    }

    private func showTableViewWithSearchResults() {
        tableView.isHidden = false
        self.searchBar.setShowsCancelButton(true, animated: true)
        UIView.animate(withDuration: 0.2) {
            self.collectionView.alpha = 0
            self.tableView.alpha = 1
        } completion: { _ in
            self.collectionView.isHidden = true
        }
    }

    func getDataIfNeeded() {
        let task = Task {
            let shouldReloadData = await viewModel.shouldReloadData()
            if shouldReloadData {
                refreshControl?.beginRefreshingManually()
            }
        }
        tasks.append(task)
    }

    private func setupSearchBar() {
        view.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.heightAnchor.constraint(equalToConstant: 50),
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
    }

    private func setupTableView() {
        tableView.alpha = 0
        tableView.isHidden = true
        view.addSubviews(tableView, spinnerView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            spinnerView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            spinnerView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            spinnerView.heightAnchor.constraint(equalToConstant: 30),
            spinnerView.widthAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func setupCollectionView() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 15),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        ])
    }

    private func handleLoadingError(error: Error) {
        refreshControl?.endRefreshing()
        let task = Task {
            let shouldReloadData = await viewModel.shouldReloadData()
            if shouldReloadData {
                showReloadButton(with: error)
            } else {
                showPopUp(issueText: error.localizedDescription)
            }
        }
        tasks.append(task)
    }
}

extension DiscoverViewController {

    private func getMorePosts() {
        let task = Task {
            guard await viewModel.isPaginationAllowed() else { return }
            factory.showLoadingIndicator()
            do {
                if let paginatedPosts = try await viewModel.getMorePostsToDiscover() {
                    self.factory.updatePostsSection(with: paginatedPosts) {
                        self.updateTableViewPosts()
                    }
                }
            } catch {
                self.factory.showPaginationRetryButton(error: error, delegate: self)
            }
            hideLoadingFooterIfNeeded()
        }
        tasks.append(task)
    }

    private func updateTableViewPosts() {
        let posts = viewModel.posts.value
        self.postsTableView.updatePostsArrayWith(posts: posts)
    }

    private func updatePostsCollectionView(with posts: [PostViewModel]) {
        if self.viewModel.posts.value.count != posts.count {
            viewModel.posts.value = posts
            self.setupDataSource()
            hideLoadingFooterIfNeeded()
        }
    }

    private func hideLoadingFooterIfNeeded() {
        Task {
            let hasHitTheEndOfPosts = await viewModel.hasHitTheEndOfPosts()
            if hasHitTheEndOfPosts {
                self.factory.hideLoadingFooter()
            } else {
                self.factory.showLoadingIndicator()
            }
        }

    }
}

extension DiscoverViewController: LoadingErrorViewDelegate {
    func didTapReloadButton() {
        hideReloadButton()
        refreshControl?.beginRefreshingManually()
    }

    private func showReloadButton(with error: Error) {
        view.addSubview(loadingErrorView)
        loadingErrorView.alpha = 1
        NSLayoutConstraint.activate([
            loadingErrorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingErrorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingErrorView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -60),
            loadingErrorView.heightAnchor.constraint(equalToConstant: 60)
        ])
        loadingErrorView.setDescriptionLabelText(error.localizedDescription)
        loadingErrorView.delegate = self
    }

    private func hideReloadButton() {
        UIView.animate(withDuration: 0.2) {
            self.loadingErrorView.alpha = 0
        } completion: { _ in
            self.loadingErrorView.removeFromSuperview()
        }
    }
}

extension DiscoverViewController: PaginationIndicatorCellDelegate {
    func didTapRetryPaginationButton() {
        getMorePosts()
    }
}

extension DiscoverViewController: CollectionViewDataSourceDelegate {

    func scrollViewDidScroll(scrollView: UIScrollView) {
        let position = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let scrollViewHeight = scrollView.frame.height
        guard position > 0 else { return }
        if position > ((contentHeight - scrollViewHeight) - 100) {
            self.getMorePosts()
        }
    }
}

extension DiscoverViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.foundUsers.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchedUserTableViewCell.identifier,
                                                       for: indexPath) as? SearchedUserTableViewCell
        else {
            fatalError("Could not cast cell")
        }

        let user = viewModel.foundUsers.value[indexPath.row]
        cell.configure(with: user)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = viewModel.foundUsers.value[indexPath.row]
        showProfile(of: user)
    }
}

extension DiscoverViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        spinnerView.startAnimating()
        timer?.invalidate()
        Task {
            timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false, block: { [weak self, searchText] _ in
                Task { @MainActor [weak self] in
                    if searchText.trimmingExtraWhitespace().count >= 3 {
                        do {
                            let lowercasedSearchText = searchText.lowercased()
                            try await self?.viewModel.searchUser(for: lowercasedSearchText)
                        } catch {
                            print("searchBar searchUser error: ", error)
                            self?.showPopUp(issueText: error.localizedDescription)
                        }
                        self?.spinnerView.stopAnimating()
                    } else {
                        self?.viewModel.foundUsers.value.removeAll()
                        self?.tableView.reloadData()
                        self?.spinnerView.stopAnimating()
                    }
                }
            })
        }
//        tasks.append(task)
    }
}

extension DiscoverViewController: UISearchTextFieldDelegate, UITextFieldDelegate {

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        showTableViewWithSearchResults()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        showCollectionViewWithPosts()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
}

extension DiscoverViewController: PostsTableViewDelegate {
    func lastVisibleItem(at indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return }
        self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
    }
    
    func updateCollectionView(with postViewModels: [PostViewModel]) {
        updatePostsCollectionView(with: postViewModels)
    }
}
