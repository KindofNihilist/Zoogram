//
//  TabBarController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//

import FirebaseAuth
import UIKit

class TabBarController: UITabBarController {

    let homeVC: HomeViewController = {
        let service = HomeFeedPostsAPIServiceAdapter(
            feedService: FeedService.shared,
            likeSystemService: LikeSystemService.shared,
            userPostService: UserPostsService.shared,
            bookmarksService: BookmarksService.shared,
            storageManager: StorageManager.shared)
        return HomeViewController(service: service)
    }()

    let userProfileVC: UserProfileViewController = {
        let service = UserProfileServiceAPIAdapter(
            userID: currentUserID(),
            followService: FollowSystemService.shared,
            userPostsService: UserPostsService.shared,
            userService: UserService.shared,
            likeSystemService: LikeSystemService.shared,
            bookmarksService: BookmarksService.shared)
        return UserProfileViewController(service: service, isTabBarItem: true)
    }()

    let activityVC: ActivityViewController = {
        let service = ActivityServiceAdapter(
            activitySystemService: ActivitySystemService.shared,
            followSystemService: FollowSystemService.shared,
            userService: UserService.shared,
            userPostsService: UserPostsService.shared)
        return ActivityViewController(service: service)
    }()

    let discoverVC = DiscoverViewController()
    let cameraRollVC = CameraRollViewController()

    var previousViewController: UIViewController?

    init(showAppearAnimation: Bool = false) {
        super.init(nibName: nil, bundle: nil)
        activityVC.delegate = self
        cameraRollVC.delegate = self
        if showAppearAnimation {
            view.alpha = 0
            view.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            animateAppearing()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        loadTabBar()
    }

    override func viewDidLoad() {
        delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(refreshUserFeed), name: NSNotification.Name("UpdateUserFeed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshUserProfile), name: NSNotification.Name("UpdateUserProfile"), object: nil)
    }

    func loadTabBar() {
        let tabItems: [UIViewController] = [homeVC, discoverVC, cameraRollVC, activityVC, userProfileVC]
        let tabIcons: [TabItem] = [.home, .discover, .makeAPost, .activity, .myProfile]
        self.setupTabBar(tabItems) { (controllers) in
            self.view.layoutIfNeeded()
            self.viewControllers = controllers
        }

        self.selectedIndex = 0

        for (index, item) in tabBar.items!.enumerated() {
            item.image = tabIcons[index].icon
            item.selectedImage = tabIcons[index].selectedIcon
        }

        tabBar.configureTabBarColor(with: .systemBackground)
        tabBar.tintColor = .label
    }

    private func setupTabBar(_ menuItems: [UIViewController], completion: @escaping ([UIViewController]) -> Void) {
        var controllers = [UIViewController]()

        menuItems.forEach {
            let navController = UINavigationController(rootViewController: $0)
            navController.navigationBar.isTranslucent = false
            navController.navigationBar.tintColor = .label
            navController.navigationBar.configureNavigationBarColor(with: .systemBackground)
            controllers.append(navController)
        }
        completion(controllers)
    }

    private func animateAppearing() {
        UIView.animate(withDuration: 0.6) {
            self.view.alpha = 1
            self.view.transform = CGAffineTransform.identity
        }
    }

    private func addNotificationBadge() {
        let barActivityItem = tabBar.items?[3]
        barActivityItem?.badgeValue = "●"

    }

    private func removeNotificationBadge() {
        let barActivityItem = tabBar.items?[3]
        barActivityItem?.badgeValue = nil
    }
}

extension TabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {

        if let navigationController = viewController as? UINavigationController,
           navigationController.viewControllers.contains(where: {$0 is CameraRollViewController}) {

            let vc = UINavigationController(rootViewController: cameraRollVC)
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
            return false
        } else {
            return true
        }
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if previousViewController == viewController {

            if let navVC = viewController as? UINavigationController, let vc = navVC.viewControllers.first as? HomeViewController {

                if vc.isViewLoaded && (vc.view.window != nil) {
                    vc.setTableViewVisibleContentToTop(animated: true)
                }
            } else if let navVC = viewController as? UINavigationController, let vc = navVC.viewControllers.first as? UserProfileViewController {

                if vc.isViewLoaded && (vc.view.window != nil) {
                    vc.setTopCollectionViewVisibleContent()
                }
            }
        }
        previousViewController = viewController
    }

    @objc func refreshUserProfile() {
        userProfileVC.getUserProfileData()
    }

    @objc func refreshUserFeed() {
        homeVC.tableView.refreshUserFeed()
    }
}

extension TabBarController: ActivityViewNotificationProtocol {
    func displayUnseenEventsBadge() {
        self.addNotificationBadge()
    }

    func removeUnseenEventsBadge() {
        self.removeNotificationBadge()
    }
}

extension TabBarController: NewPostProtocol {
    func makeANewPost(post: UserPost, completion: @escaping () -> Void) {

        homeVC.setTableViewVisibleContentToTop(animated: false)

        cameraRollVC.dismiss(animated: true) {
            let currentUser = self.userProfileVC.getCurrentUserProfile()
            self.homeVC.showMakingNewPostNotificationViewFor(username: currentUser.username, with: post.image)

            self.homeVC.service.makeANewPost(post: post) { progress in
                self.homeVC.updateProgressBar(progress: progress)
            } completion: { result in

                switch result {

                case .success():
                    post.author = currentUser
                    self.homeVC.animateInsertionOfCreatedPost(post: post)
                    self.userProfileVC.getUserProfileData()

                case .failure(let error):
                    self.homeVC.show(error: error)
                }
            }
        }
    }
}
