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

    private let searchContainerView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        self.postsTableView.title = String(localized: "Discover")
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(getPosts), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        refreshControl?.beginRefreshingManually()
    }

    @objc private func getPosts() {
        loadingErrorView.removeFromSuperview()
        viewModel.getPostsToDiscover { result in
            switch result {
            case .success:
                self.factory = DiscoverCollectionViewFactory(for: self.collectionView)
                self.postsTableView.updatePostsArrayWith(posts: self.viewModel.posts.value)
                self.refreshControl?.endRefreshing()
                self.setupDataSource()
            case .failure(let error):
                self.handleLoadingError(error: error)
            }
        }
    }

    private func setupDataSource() {
        factory.buildSections(for: viewModel.posts.value)
        let dataSource = DefaultCollectionViewDataSource(sections: factory.sections)
        dataSource.delegate = self
        self.dataSource = dataSource
        self.collectionView.delegate = dataSource
        self.collectionView.dataSource = dataSource
        factory.cellAction = { indexPath in
            guard self.viewModel.posts.value.isEmpty != true else { return }
            self.postsTableView.focusTableViewOnPostWith(index: indexPath)
            self.navigationController?.pushViewController(self.postsTableView, animated: true)
        }
        self.collectionView.reloadData()
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
        if viewModel.hasLoadedData() == false {
            refreshControl?.beginRefreshingManually()
        }
    }

    private func setupSearchBar() {
        view.addSubview(searchContainerView)
        searchContainerView.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            searchContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            searchBar.heightAnchor.constraint(equalToConstant: 50),
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: searchContainerView.leadingAnchor, constant: 10),
            searchBar.trailingAnchor.constraint(equalTo: searchContainerView.trailingAnchor, constant: -10),
            searchBar.bottomAnchor.constraint(equalTo: searchContainerView.bottomAnchor, constant: -3)
        ])
    }

    private func setupTableView() {
        tableView.alpha = 0
        tableView.isHidden = true
        view.addSubviews(tableView, spinnerView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchContainerView.bottomAnchor),
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
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func handleLoadingError(error: Error) {
        refreshControl?.endRefreshing()
        if viewModel.hasLoadedData() {
            showPopUp(issueText: error.localizedDescription)
        } else {
            showReloadButton(with: error)
        }
    }
}

extension DiscoverViewController {

    private func getMorePosts() {
        factory.showLoadingIndicator()
        viewModel.getMorePostsToDiscover { result in
            switch result {
            case .success(let paginatedPosts):
                if let unwrappedPosts = paginatedPosts {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.factory.updatePostsSection(with: unwrappedPosts) {
                            self.updateTableViewPosts()
                            self.viewModel.hasFinishedPaginating()
                            self.hideLoadingFooterIfNeeded()
                        }
                    }
                }
            case .failure(let error):
                self.factory.showPaginationRetryButton(error: error, delegate: self)
            }
        }
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
        if self.viewModel.hasHitTheEndOfPosts() {
            self.factory.hideLoadingFooter()
        } else {
            self.factory.showLoadingIndicator()
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
        guard viewModel.isPaginationAllowed() else { return }
        let position = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let scrollViewHeight = scrollView.frame.height

        if position > ((contentHeight - scrollViewHeight) - 50) {
            self.getMorePosts()
        }
    }
}

extension DiscoverViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.foundUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchedUserTableViewCell.identifier,
                                                       for: indexPath) as? SearchedUserTableViewCell
        else {
            fatalError("Could not cast cell")
        }

        let user = viewModel.foundUsers[indexPath.row]
        cell.usernameLabel.text = user.username
        cell.nameLabel.text = user.name
        cell.profileImageView.image = user.getProfilePhoto()
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = viewModel.foundUsers[indexPath.row]
        let service = createUserProfileDefaultServiceFor(userID: user.userID)
        let userProfileViewController = UserProfileViewController(service: service, user: user, isTabBarItem: false)
        userProfileViewController.title = user.username
        self.navigationController?.pushViewController(userProfileViewController, animated: true)
    }
}

extension DiscoverViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        spinnerView.startAnimating()
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false, block: { [weak self, searchText] _ in
            guard let self = self else { return }
            if searchText.trimmingExtraWhitespace().count >= 3 {
                self.viewModel.searchUser(for: searchText) { [weak self] result in
                    switch result {
                    case .success:
                        self?.tableView.reloadData()
                    case .failure(let error):
                        self?.showPopUp(issueText: error.localizedDescription)
                    }
                    self?.spinnerView.stopAnimating()
                }
            } else {
                self.viewModel.foundUsers.removeAll()
                self.tableView.reloadData()
                self.spinnerView.stopAnimating()
            }
        })
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
    func updateCollectionView(with postViewModels: [PostViewModel]) {
        updatePostsCollectionView(with: postViewModels)
    }
}
