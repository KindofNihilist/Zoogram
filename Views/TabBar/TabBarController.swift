//
//  TabBarController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//

import FirebaseAuth
import UIKit

class TabBarController: UITabBarController {

    private var tasks = [Task<Void, Never>?]()
    private var currentUser: ZoogramUser
    private var isBeingPresentedForTheFirstTime: Bool = true
    private var shouldShowAppearAnimation: Bool

    private var connectionMonitor: NetworkStatusMonitor?

    let homeVC: HomeViewController = {
        let service = HomeFeedService(
            feedService: FeedService.shared,
            likeSystemService: LikeSystemService.shared,
            userPostsService: UserPostsService.shared,
            bookmarksService: BookmarksSystemService.shared,
            storageManager: StorageManager.shared,
            userDataService: UserDataService.shared,
            imageService: ImageService.shared,
            commentsService: CommentSystemService.shared)
        return HomeViewController(service: service)
    }()

    let discoverVC: DiscoverViewController = {
        let service = DiscoverService(
            searchService: SearchService(),
            userDataService: UserDataService.shared,
            discoverPostsService: DiscoverPostsService.shared,
            likeSystemService: LikeSystemService.shared,
            userPostsService: UserPostsService.shared,
            bookmarksService: BookmarksSystemService.shared,
            imageService: ImageService.shared,
            commentsService: CommentSystemService.shared)
        return DiscoverViewController(service: service)
    }()

    let cameraRollVC = CameraRollViewController()

    let activityVC: ActivityViewController = {
        let service = ActivityService(
            activitySystemService: ActivitySystemService.shared,
            followSystemService: FollowSystemService.shared,
            userDataService: UserDataService(),
            userPostsService: UserPostsService.shared,
            storageManager: StorageManager.shared)
        return ActivityViewController(service: service)
    }()

    lazy var userProfileVC: UserProfileViewController = {
        let service = UserProfileService(
            userID: currentUser.userID,
            followService: FollowSystemService.shared,
            userPostsService: UserPostsService.shared,
            userService: UserDataService(),
            likeSystemService: LikeSystemService.shared,
            bookmarksService: BookmarksSystemService.shared,
            activityService: ActivitySystemService.shared,
            imageService: ImageService.shared,
            commentsService: CommentSystemService.shared)
        return UserProfileViewController(service: service, user: self.currentUser, isTabBarItem: true)
    }()

    private lazy var noseButton: CatNoseButton = {
        let button = CatNoseButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    var previousViewController: UIViewController?

    var generator = UISelectionFeedbackGenerator()

    private var noseButtonSize = CGSize(width: 65, height: 65)

    init(for user: ZoogramUser, showAppearAnimation: Bool = false) {
        self.currentUser = user
        self.shouldShowAppearAnimation = showAppearAnimation
        super.init(nibName: nil, bundle: nil)
        activityVC.delegate = self
        cameraRollVC.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshUserFeed),
            name: NSNotification.Name("UpdateUserFeed"),
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshUserProfile),
            name: NSNotification.Name("UpdateUserProfile"),
            object: nil)
        loadTabBar()
        setupConnectionMonitor()
        setupCurrentUserListener()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if shouldShowAppearAnimation {
            self.hideUIElements(animate: false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldShowAppearAnimation {
            self.showUIElements(animate: true)
            self.shouldShowAppearAnimation = false
        }
        if isBeingPresentedForTheFirstTime {
            setupNoseButton()
            isBeingPresentedForTheFirstTime = false
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tasks.forEach { task in
            task?.cancel()
        }
    }

    private func setupNoseButton() {
        let multiplier = hasBottomSafeArea() ? 1.25 : 1.1
        self.tabBar.addSubview(noseButton)
        noseButton.addTarget(self, action: #selector(didTapNose), for: .touchUpInside)
        NSLayoutConstraint.activate([
            noseButton.heightAnchor.constraint(equalTo: tabBar.safeAreaLayoutGuide.heightAnchor, multiplier: multiplier),
            noseButton.widthAnchor.constraint(equalTo: tabBar.safeAreaLayoutGuide.heightAnchor, multiplier: multiplier),
            noseButton.centerXAnchor.constraint(equalTo: tabBar.centerXAnchor),
            noseButton.topAnchor.constraint(equalTo: tabBar.topAnchor, constant: -3)
        ])
    }

    func loadTabBar() {
        let tabItems: [UIViewController] = [homeVC, discoverVC, cameraRollVC, activityVC, userProfileVC]
        let tabIcons: [TabItem] = [.home, .discover, .makeAPost, .activity, .myProfile]
        self.setupTabBar(tabItems) { (controllers) in
            self.viewControllers = controllers
        }
        self.selectedIndex = 0
        self.tabBar.items?[2].isEnabled = false
        for (index, item) in tabBar.items!.enumerated() {
            item.image = tabIcons[index].icon
            item.selectedImage = tabIcons[index].selectedIcon
        }
        tabBar.tintColor = Colors.label
    }

    private func setupTabBar(_ menuItems: [UIViewController], completion: @escaping ([UIViewController]) -> Void) {
        var controllers = [UIViewController]()
        menuItems.forEach {
            let navController = UINavigationController(rootViewController: $0)
//            navController.navigationBar.isTranslucent = false
            navController.navigationBar.tintColor = Colors.label
            controllers.append(navController)
        }
        cameraRollVC.navigationController?.modalPresentationStyle = .fullScreen
        completion(controllers)
    }

    private func addNotificationBadge() {
        let barActivityItem = tabBar.items?[3]
        barActivityItem?.badgeValue = "●"
    }

    private func removeNotificationBadge() {
        let barActivityItem = tabBar.items?[3]
        barActivityItem?.badgeValue = nil
    }

    @objc func didTapNose() {
        let viewController = UINavigationController(rootViewController: cameraRollVC)
        viewController.modalPresentationStyle = .fullScreen
        present(viewController, animated: true)
    }

    private func setupCurrentUserListener() {
        UserDataService().observeUser(with: currentUser.userID) { result in
            switch result {
            case .success(let currentUser):
                let task = Task {
                    await UserManager.shared.updateCurrentUserModel(currentUser)
                    self.currentUser = currentUser
                    self.userProfileVC.updateProfileHeader()
                }
                self.tasks.append(task)
            case .failure(let error):
                self.selectedViewController?.showPopUp(issueText: error.localizedDescription)
            }
        }
    }

    private func setupConnectionMonitor() {
        let task = Task {
            self.connectionMonitor = NetworkStatusMonitor()
            await self.connectionMonitor?.setHandler({ connectionState in
                Task { @MainActor in
                    if connectionState == .disconnected {
                        guard let currentVC = self.selectedViewController else { return }
                        await self.connectionMonitor?.setConnectionHandlerState(isBeingHandled: true)
                        currentVC.showPopUp(issueText: String(localized: "No Internet Connection")) {
                            Task {
                                await self.connectionMonitor?.setConnectionHandlerState(isBeingHandled: false)
                            }
                        }
                    } else if connectionState == .connected {
                        self.activityVC.observeActivityEvents()
                        self.userProfileVC.getUserProfileDataAndPostsIfNeeded()
                        self.homeVC.shouldRefreshFeedIfNeeded()
                        self.discoverVC.getDataIfNeeded()
                    }
                }
            })
        }
        tasks.append(task)
    }
}

extension TabBarController: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {

        if previousViewController == viewController {
            if let navVC = viewController as? UINavigationController {

                if let homeVC = navVC.viewControllers.first as? HomeViewController {
                    if homeVC.isViewLoaded && (homeVC.view.window != nil) {
                        homeVC.setTableViewVisibleContentToTop(animated: true)
                    }
                }
                if let userProfileVC = navVC.viewControllers.first as? UserProfileViewController {
                    if userProfileVC.isViewLoaded && (userProfileVC.view.window != nil) {
                        userProfileVC.setTopCollectionViewVisibleContent()
                    }
                }
            }
        } else {
            generator.prepare()
            generator.selectionChanged()
        }
        previousViewController = viewController
    }

    @objc func refreshUserProfile() {
        userProfileVC.getUserProfileDataAndPosts()
    }

    @objc func refreshUserFeed() {
        homeVC.tableView.getPosts()
    }
}

extension TabBarController: ActivityViewNotificationProtocol {

    func removeUnseenEventsBadge() {
        self.removeNotificationBadge()
    }

    func displayUnseenEventsBadge() {
        self.addNotificationBadge()
    }

}

extension TabBarController: NewPostProtocol {
    func makeANewPost(post: UserPost) {
        self.selectedIndex = 0
        homeVC.setTableViewVisibleContentToTop(animated: false)
        homeVC.removeNoPostsNotificationIfDisplayed()
        cameraRollVC.dismiss(animated: true) {
            self.homeVC.makeNewPost(with: post, for: self.currentUser) {
                self.userProfileVC.getUserProfileDataAndPosts()
            }
        }
    }
}
