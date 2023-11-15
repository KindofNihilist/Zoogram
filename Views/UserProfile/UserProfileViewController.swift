//
//  ProfileViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//
import SDWebImage
import FirebaseAuth
import UIKit
import AVFoundation

final class UserProfileViewController: UIViewController {

    var service: UserProfileService!

    private var viewModel = UserProfileViewModel()

    private(set) var dataSource: CollectionViewDataSource?

    private(set) var factory: UserProfileFactory!

    private var postTableViewController: PostViewController

    private var profileRefreshControl: UIRefreshControl?

    private var isTabBarItem: Bool

    private var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .vertical
        layout.sectionInsetReference = .fromSafeArea
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        return collectionView
    }()

    private lazy var settingsButton: UIBarButtonItem = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 5, height: 5))
        button.setImage(UIImage(named: "menuIcon"), for: .normal)
        button.addTarget(self, action: #selector(didTapSettingsButton), for: .touchUpInside)
        button.tintColor = .label
        let barButtonItem = UIBarButtonItem(customView: button)
        barButtonItem.customView?.widthAnchor.constraint(equalToConstant: 20).isActive = true
        barButtonItem.customView?.heightAnchor.constraint(equalToConstant: 20).isActive = true
        return barButtonItem
    }()

    lazy var userNicknameLabel: UILabel = {
        let label = UILabel()
        label.font = CustomFonts.boldFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(service: UserProfileService, user: ZoogramUser? = nil, isTabBarItem: Bool) {
        self.service = service
        self.viewModel.insertUserIfPreviouslyObtained(user: user)
        self.postTableViewController = PostViewController(posts: viewModel.posts.value, service: self.service)
        self.isTabBarItem = isTabBarItem
        super.init(nibName: nil, bundle: nil)
        self.setupCollectionView()
        self.setupRefreshControl()

        self.viewModel.posts.bind { posts in
            self.postTableViewController.updatePostsArrayWith(posts: posts)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        getUserProfileData()
    }

    func getCurrentUserProfile() -> ZoogramUser {
        return viewModel.user
    }

    func setupRefreshControl() {
        profileRefreshControl = UIRefreshControl()
        profileRefreshControl?.addTarget(self, action: #selector(getUserProfileData), for: .valueChanged)
        collectionView.refreshControl = profileRefreshControl
    }

    private func configureNavigationBar() {
        setUserNickname()
        navigationItem.rightBarButtonItem = settingsButton
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: userNicknameLabel)
    }

    private func setUserNickname() {
        userNicknameLabel.text = viewModel.user.username
    }

    private func updateTableViewPosts() {
        let posts = viewModel.posts.value
        self.postTableViewController.updatePostsArrayWith(posts: posts)
    }

    // MARK: CollectionView Setup
    private func setupCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
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

    @objc func getUserProfileData() {
        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        service.getUserProfileViewModel { viewModel in
            self.viewModel.updateValuesWithViewModel(viewModel)

            if self.isTabBarItem {
                self.configureNavigationBar()
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        service.getPosts { posts in
            self.viewModel.posts.value = posts
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            self.factory = UserProfileFactory(for: self.collectionView, headerDelegate: self)
            self.setupDatasource()

            if self.service.hasHitTheEndOfPosts {
                self.factory.hideLoadingFooter()
            } else {
                self.factory.showLoadingIndicator()
            }
            self.collectionView.refreshControl?.endRefreshing()
        }
    }

    @objc private func didTapSettingsButton() {
        let settingsVC = SettingsViewController()
        settingsVC.hidesBottomBarWhenPushed = true
        settingsVC.title = "Settings"
        self.navigationController?.pushViewController(settingsVC, animated: true)
    }
}

// MARK: CollectionView Datasource setup
extension UserProfileViewController {

    func setupDatasource() {
        self.factory.buildSections(profileViewModel: self.viewModel)
        let dataSource = DefaultCollectionViewDataSource(sections: factory.sections)
        dataSource.delegate = self
        self.dataSource = dataSource
        self.collectionView.dataSource = dataSource
        self.collectionView.delegate = dataSource
        self.factory.postCellAction = { indexPath in
            self.postSelectAction(at: indexPath)
        }
        self.collectionView.reloadData()
    }
}

extension UserProfileViewController: CollectionViewDataSourceDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {

        let position = scrollView.contentOffset.y

        if position > (collectionView.contentSize.height - 100 - scrollView.frame.size.height) {
            guard service.hasHitTheEndOfPosts == false && service.isPaginationAllowed else {
                if service.hasHitTheEndOfPosts {
                    factory.setShouldDisplayLoadingFooter(false)
                    factory.hideLoadingFooter()
                }
                return
            }
            service.getMorePosts { paginatedPosts in
                if let unwrappedPosts = paginatedPosts {
                    let postsCountBeforeUpdate = self.viewModel.posts.value.count
                    self.viewModel.posts.value.append(contentsOf: unwrappedPosts)
                    self.factory.updatePostsSection(with: unwrappedPosts)
                    self.updateTableViewPosts()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        let postsCountAfterUpdate = self.viewModel.posts.value.count
                        let indexPaths = (postsCountBeforeUpdate ..< postsCountAfterUpdate).map {
                            IndexPath(row: $0, section: 1)
                        }
                        self.collectionView.performBatchUpdates {
                            self.collectionView.insertItems(at: indexPaths)
                        } completion: { _ in
                            self.service.isPaginationAllowed = true
                            if self.service.hasHitTheEndOfPosts {
                                self.factory.hideLoadingFooter()
                            }
                        }
                    }
                }
            }
        }
    }

    func postSelectAction(at indexPath: IndexPath) {
        guard viewModel.posts.value.isEmpty != true else {
            return
        }
        self.postTableViewController.focusTableViewOnPostWith(index: indexPath)
        self.navigationController?.pushViewController(self.postTableViewController, animated: true)
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
        let user = viewModel.user
        // open tableview of people user follows
        let followListVC = FollowListViewController(for: user.userID,
                                                    isUserProfile: viewModel.isCurrentUserProfile,
                                                    viewKind: .following)
        followListVC.title = "Following"
        navigationController?.pushViewController(followListVC, animated: true)
    }

    func followersButtonTapped() {
        let user = viewModel.user
        // open viewcontroller with tableview of people following user
        let followListVC = FollowListViewController(for: user.userID,
                                                    isUserProfile: viewModel.isCurrentUserProfile,
                                                    viewKind: .followers)
        followListVC.title = "Followers"
        navigationController?.pushViewController(followListVC, animated: true)
    }

    func editProfileButtonTapped() {
        let profileEditingVC = ProfileEdditingViewController(userProfileViewModel: self.viewModel)
        present(UINavigationController(rootViewController: profileEditingVC), animated: true)
    }

    func followButtonTapped(completion: @escaping (FollowStatus) -> Void) {
        service.followUser { [weak self] followStatus in
            self?.viewModel.user.followStatus = followStatus
            completion(followStatus)
        }
    }

    func unfollowButtonTapped(completion: @escaping (FollowStatus) -> Void) {
        service.unfollowUser { [weak self] followStatus in
            self?.viewModel.user.followStatus = followStatus
            completion(followStatus)
        }
    }
}

extension UserProfileViewController: ProfileTabsCollectionViewDelegate {
    func didTapGridTabButton() {

    }

    func didTapTaggedTabButton() {

    }
}

extension UserProfileViewController: UserProfilePostsTableViewProtocol {
    func updateUserProfilePosts() {
        self.getUserProfileData()
    }
}
