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
    private(set) var factory: UserProfileFactory!

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
        self.viewModel = UserProfileViewModel(service: service)
        self.viewModel.user = user
        self.postTableViewController = PostsTableViewController(posts: viewModel.posts.value, service: service)
        self.isTabBarItem = isTabBarItem
        super.init()
        self.view.backgroundColor = Colors.background
        self.mainView = collectionView
        self.setupCollectionView()
        self.setupRefreshControl()
        self.postTableViewController.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel.posts.bind { posts in
            Task.detached(priority: .high) {
                await self.postTableViewController.updatePostsArrayWith(posts: posts)
            }
        }
        getUserProfileDataAndPosts()
        self.postTableViewController.updateTableViewFrame(to: self.view.frame)
        self.reloadAction = {
            self.getUserProfileDataAndPosts()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func setupRefreshControl() {
        profileRefreshControl = UIRefreshControl()
        profileRefreshControl?.addTarget(self, action: #selector(getUserProfileDataAndPosts), for: .valueChanged)
        collectionView.refreshControl = profileRefreshControl
    }

    private func configureNavigationBar() {
        userNicknameLabel.text = viewModel.user.username
        navigationItem.rightBarButtonItem = settingsButton
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: userNicknameLabel)
    }

    @MainActor
    private func updateTableViewPosts() {
        let posts = viewModel.posts.value
        self.postTableViewController.updatePostsArrayWith(posts: posts)
    }

    private func updatePostsCollectionView(with posts: [PostViewModel]) {
        if self.viewModel.posts.value.count != posts.count {
            viewModel.posts.value = posts
            print("collectionView update postsCount ", posts.count)
            self.setupDatasource()
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

    func updateUserModel(_ usermodel: ZoogramUser) {
        viewModel.user = usermodel
    }

    func getUserProfileDataAndPostsIfNeeded() {
        if viewModel.hasLoadedData() == false {
            getUserProfileDataAndPosts()
        }
    }

    @objc func getUserProfileDataAndPosts() {
        Task {
            do {
                try await viewModel.getUserProfileData()
                try await viewModel.getPosts()
                self.removeLoadingErrorNotificationIfDisplayed()
                self.factory = UserProfileFactory(for: self.collectionView, headerDelegate: self)
                self.setupDatasource()
                self.showMainView()
                self.hideLoadingFooterIfNeeded()
                self.collectionView.refreshControl?.endRefreshing()
                if self.viewModel.isCurrentUserProfile && self.isTabBarItem {
                    self.configureNavigationBar()
                }
            } catch {
                self.handleLoadingError(error: error)
            }
        }
    }

    private func getMorePosts() {
        factory.showLoadingIndicator()
        Task { @MainActor in
            do {
                let paginatedPosts = try await viewModel.getMorePosts()
                try await Task.sleep(for: .seconds(0.5))
                if let unwrappedPosts = paginatedPosts {
                    self.factory.updatePostsSection(with: unwrappedPosts) {
                        self.updateTableViewPosts()
                        self.viewModel.hasFinishedPaginating()
                        self.hideLoadingFooterIfNeeded()
                    }
                }
            } catch {
                self.factory.showPaginationRetryButton(error: error, delegate: self)
            }
        }
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
        let settingsVC = SettingsViewController(currentUserViewModel: self.viewModel)
        settingsVC.hidesBottomBarWhenPushed = true
        settingsVC.title = String(localized: "Settings")
        self.navigationController?.pushViewController(settingsVC, animated: true)
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
            guard self.viewModel.posts.value.isEmpty != true else { return }
            self.postTableViewController.focusTableViewOnPostWith(index: indexPath)
            self.navigationController?.pushViewController(self.postTableViewController, animated: true)
        }
        self.collectionView.reloadData()
    }
}

extension UserProfileViewController: CollectionViewDataSourceDelegate {

    func scrollViewDidScroll(scrollView: UIScrollView) {
        guard viewModel.isPaginationAllowed() else { return }
        let position = scrollView.contentOffset.y
        let contentHeight = collectionView.contentSize.height
        let scrollViewHeight = scrollView.frame.size.height

        if position > (contentHeight - scrollViewHeight - 100) {
            self.getMorePosts()
        }
    }
}

// MARK: ProfileHeaderDelegate
extension UserProfileViewController: ProfileHeaderDelegate {

    func postsButtonTapped() {
        guard viewModel.posts.value.isEmpty != true else {
            return
        }
        // center view on the posts section
        collectionView.scrollToItem(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
    }

    func followingButtonTapped() {
        // open tableview of people user follows
        let user = viewModel.user
        let service = FollowedListService(for: user.userID, followSystemService: FollowSystemService.shared)
        let followListVC = FollowedListViewController(service: service, isUserProfile: user.isCurrentUserProfile)
        followListVC.title = String(localized: "Following")
        navigationController?.pushViewController(followListVC, animated: true)
    }

    func followersButtonTapped() {
        // open viewcontroller with tableview of people following user
        let user = viewModel.user
        let service = FollowersListService(for: user.userID, followSystemService: FollowSystemService.shared)
        let followListVC = FollowersListViewController(service: service, isUserProfile: user.isCurrentUserProfile)
        followListVC.title = String(localized: "Followers")
        navigationController?.pushViewController(followListVC, animated: true)
    }

    func editProfileButtonTapped() {
        let service = UserDataValidationService()
        let profileEditingVC = ProfileEdditingViewController(userProfileViewModel: self.viewModel, service: service)
        let navigationController = UINavigationController(rootViewController: profileEditingVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }

    func followButtonTapped(completion: @escaping (FollowStatus) -> Void) {
        Task { @MainActor in
            do {
                let newFollowStatus = try await viewModel.followUser()
                completion(newFollowStatus)
            } catch {
                self.showPopUp(issueText: error.localizedDescription)
            }
        }
    }

    func unfollowButtonTapped(completion: @escaping (FollowStatus) -> Void) {
        Task { @MainActor in
            do {
                let newFollowStatus = try await viewModel.unfollowUser()
                completion(newFollowStatus)
            } catch {
                self.showPopUp(issueText: error.localizedDescription)
            }
        }
    }
}

extension UserProfileViewController: PostsTableViewDelegate {
    func updateCollectionView(with postViewModels: [PostViewModel]) {
        updatePostsCollectionView(with: postViewModels)
    }
}

extension UserProfileViewController: PaginationIndicatorCellDelegate {
    func didTapRetryPaginationButton() {
        getMorePosts()
    }
}
