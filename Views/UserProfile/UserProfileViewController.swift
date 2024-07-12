//
//  ProfileViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//
import UIKit

final class UserProfileViewController: ViewControllerWithLoadingIndicator {

    private let viewModel: UserProfileViewModel
    private(set) var dataSource: CollectionViewDataSource?

    private lazy var factory: UserProfileFactory = {
        UserProfileFactory(for: self.collectionView, headerDelegate: self)
    }()

    private var tasks = [Task<Void, Never>?]()

    private var postTableViewController: PostsTableViewController
    private var profileRefreshControl: UIRefreshControl?
    private var isTabBarItem: Bool

    private var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .vertical
        layout.sectionInsetReference = .fromSafeArea
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = Colors.background
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()

    private lazy var settingsButton: UIBarButtonItem = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        button.setImage(UIImage(named: "menuIcon"), for: .normal)
        button.addTarget(self, action: #selector(didTapSettingsButton), for: .touchUpInside)
        button.tintColor = Colors.label
        let barButtonItem = UIBarButtonItem(customView: button)
        barButtonItem.customView?.widthAnchor.constraint(equalToConstant: 22).isActive = true
        barButtonItem.customView?.heightAnchor.constraint(equalToConstant: 22).isActive = true
        return barButtonItem
    }()

    private lazy var userNicknameLabel: UILabel = {
        let label = UILabel()
        label.font = CustomFonts.boldFont(ofSize: 21)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(service: any UserProfileServiceProtocol, user: ZoogramUser, isTabBarItem: Bool) {
        self.viewModel = UserProfileViewModel(service: service, user: user)
        self.postTableViewController = PostsTableViewController(posts: viewModel.posts, service: service)
        self.isTabBarItem = isTabBarItem
        super.init()
        self.view.backgroundColor = Colors.background
        self.mainView = collectionView
        self.setupCollectionView()
        self.setupRefreshControl()
        self.postTableViewController.delegate = self
        self.postTableViewController.title = String(localized: "Posts")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        getUserProfileDataAndPosts()
        self.postTableViewController.updateTableViewFrame(to: self.view.frame)
        self.reloadAction = {
            self.getUserProfileDataAndPosts()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tasks.forEach { task in
            task?.cancel()
        }
    }

    func setupRefreshControl() {
        profileRefreshControl = UIRefreshControl()
        profileRefreshControl?.addTarget(self, action: #selector(getUserProfileDataAndPosts), for: .valueChanged)
        collectionView.refreshControl = profileRefreshControl
    }

    private func configureNavigationBar() {
        userNicknameLabel.text = viewModel.username
        navigationItem.rightBarButtonItem = settingsButton
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: userNicknameLabel)
    }

    func updateProfileHeader() {
        Task {
            await viewModel.updateCurrentUserModel()
            factory.refreshProfileHeader(with: viewModel)
        }
    }

    private func updateTableViewPosts() {
        let posts = viewModel.posts
        self.postTableViewController.updatePostsArrayWith(posts: posts)
    }

    private func updatePostsCollectionView(with posts: [PostViewModel]) {
        if self.viewModel.posts.count != posts.count {
            viewModel.posts = posts
            self.setupDatasource()
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

    // MARK: CollectionView Setup
    private func setupCollectionView() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func setTopCollectionViewVisibleContent() {
        self.collectionView.setContentOffset(CGPoint.zero, animated: true)
    }

    func getUserProfileDataAndPostsIfNeeded() {
        Task {
            let shouldReloadData = await viewModel.shouldReloadData()
            if shouldReloadData {
                getUserProfileDataAndPosts()
            }
        }
    }

    @objc func getUserProfileDataAndPosts() {
        print("getUserProfileDataAndPosts triggered")
        let task = Task {
            do {
                try await viewModel.getUserProfileData()
                try await viewModel.getPosts()
                self.removeLoadingErrorNotificationIfDisplayed()
                self.setupDatasource()
                self.updateTableViewPosts()
                self.showMainView()
                self.collectionView.refreshControl?.endRefreshing()
                if self.viewModel.isCurrentUserProfile && self.isTabBarItem {
                    self.configureNavigationBar()
                }
            } catch {
                self.handleLoadingError(error: error)
            }
        }
        tasks.append(task)
    }

    private func getMorePosts() {
        let task = Task {
            guard await viewModel.isPaginationAllowed() else { return }
            factory.showLoadingIndicator()
            do {
                if let paginatedPosts = try await viewModel.getMorePosts() {
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

    private func handleLoadingError(error: Error) {
        if isMainViewVisible {
            self.showPopUp(issueText: error.localizedDescription)
            self.collectionView.refreshControl?.endRefreshing()
        } else {
            self.showLoadingErrorNotification(text: error.localizedDescription)
        }
    }

    @objc private func didTapSettingsButton() {
        let settingsVC = SettingsViewController()
        settingsVC.hidesBottomBarWhenPushed = true
        settingsVC.title = String(localized: "Settings")
        self.navigationController?.pushViewController(settingsVC, animated: true)
    }

    private func showPost(at indexPath: IndexPath) {
        guard self.viewModel.posts.isEmpty != true else { return }
        self.postTableViewController.focusTableViewOnPostWith(index: indexPath)
        if #available(iOS 18.0, *) {
            self.postTableViewController.preferredTransition = .zoom { context in
                let postsTableView = context.zoomedViewController as! PostsTableViewController
                let lastSeenPostIndexPath = postsTableView.getLastVisibleCellIndexPath() ?? indexPath
                let collectionViewIndexPath = IndexPath(row: lastSeenPostIndexPath.row, section: indexPath.section)
                return self.collectionView.cell(at: collectionViewIndexPath)
            }
        }
        self.navigationController?.pushViewController(self.postTableViewController, animated: true)
    }
}

// MARK: CollectionView Datasource setup
extension UserProfileViewController {

    func setupDatasource() {
        factory.buildSections(profileViewModel: self.viewModel)
        let dataSource = DefaultCollectionViewDataSource(sections: factory.getSections())
        dataSource.delegate = self
        self.dataSource = dataSource
        self.collectionView.dataSource = dataSource
        self.collectionView.delegate = dataSource
        self.factory.postCellAction = { indexPath in
            self.showPost(at: indexPath)
        }
        self.collectionView.reloadData()
    }
}

extension UserProfileViewController: CollectionViewDataSourceDelegate {

    func scrollViewDidScroll(scrollView: UIScrollView) {
        let position = scrollView.contentOffset.y
        let contentHeight = collectionView.contentSize.height
        let scrollViewHeight = scrollView.frame.size.height
        guard position > 0 else { return }
        if position > (contentHeight - scrollViewHeight - 100) {
            self.getMorePosts()
        }
    }
}

// MARK: ProfileHeaderDelegate
extension UserProfileViewController: ProfileHeaderDelegate {

    func postsButtonTapped() {
        guard viewModel.posts.isEmpty != true else {
            return
        }
        // center view on the posts section
        collectionView.scrollToItem(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
    }

    func followingButtonTapped() {
        // open tableview of people user follows
        let service = FollowedListService(
            for: viewModel.userID,
            followSystemService: FollowSystemService.shared,
            userDataService: UserDataService())
        let followListVC = FollowedListViewController(service: service, isUserProfile: viewModel.isCurrentUserProfile)
        followListVC.title = String(localized: "Following")
        navigationController?.pushViewController(followListVC, animated: true)
    }

    func followersButtonTapped() {
        // open viewcontroller with tableview of people following user
        let service = FollowersListService(
            for: viewModel.userID,
            followSystemService: FollowSystemService.shared,
            userDataService: UserDataService())
        let followListVC = FollowersListViewController(service: service, isUserProfile: viewModel.isCurrentUserProfile)
        followListVC.title = String(localized: "Followers")
        navigationController?.pushViewController(followListVC, animated: true)
    }

    func editProfileButtonTapped() {
        showProfileSettings()
    }

    func followButtonTapped() {
        let task = Task {
            do {
                try await viewModel.followUser()
            } catch {
                self.showPopUp(issueText: error.localizedDescription)
            }
        }
        tasks.append(task)
    }

    func unfollowButtonTapped() {
        let task = Task {
            do {
                try await viewModel.unfollowUser()
            } catch {
                self.showPopUp(issueText: error.localizedDescription)
            }
        }
        tasks.append(task)
    }
}

extension UserProfileViewController: PostsTableViewDelegate {
    func lastVisibleItem(at indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return }
        guard let postsSectionIndex = factory.getPostsSectionIndex() else { return }
        let adaptedIndexPath = IndexPath(row: indexPath.row, section: postsSectionIndex)
        self.collectionView.scrollToItem(at: adaptedIndexPath, at: .centeredVertically, animated: false)
    }
    
    func updateCollectionView(with postViewModels: [PostViewModel]) {
        updatePostsCollectionView(with: postViewModels)
    }
}

extension UserProfileViewController: PaginationIndicatorCellDelegate {
    func didTapRetryPaginationButton() {
        getMorePosts()
    }
}
