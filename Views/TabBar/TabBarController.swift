//
//  TabBarController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//

import FirebaseAuth
import UIKit

class TabBarController: UITabBarController {
    
    let homeVC = HomeViewController()
    let discoverVC = DiscoverViewController()
    let cameraRollVC = CameraRollViewController()
    let activityVC = ActivityViewController()
    let userProfileVC: UserProfileViewController = {
        let service = UserProfileServiceAPIAdapter(
            userID: currentUserID(),
            followService: FollowService.shared,
            userPostsService: UserPostsService.shared,
            userService: UserService.shared,
            likeSystemService: LikeSystemService.shared,
            bookmarksService: BookmarksService.shared)
        let vc = UserProfileViewController(service: service, isTabBarItem: true)
        
        return vc
    }()
    
    var previousViewController: UIViewController?
    
    var events = [ActivityEvent]()
    
    override func viewWillAppear(_ animated: Bool) {
        loadTabBar()
    }
    
    override func viewDidLoad() {
        delegate = self
        cameraRollVC.delegate = self
        activityVC.delegate = self
        listenToActivityEvents()
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshUserFeed), name: NSNotification.Name("UpdateUserFeed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshUserProfile), name: NSNotification.Name("UpdateUserProfile"), object: nil)
//        addTestingButton()
    }
    
    init(showAppearAnimation: Bool = false) {
        super.init(nibName: nil, bundle: nil)
        if showAppearAnimation {
            view.alpha = 0
            view.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            animateAppearing()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    private func listenToActivityEvents() {
        ActivityService.shared.observeActivityEvents() { events in
            self.events = events
            self.activityVC.updateEvents(events)
            let hasUnseenEvents = events.filter({$0.seen == false}).count > 0
            if hasUnseenEvents {
                self.addNotificationBadge()
            } else {
                self.removeNotificationBadge()
            }
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
    
    private func addTestingButton() {
        let testButton = UIButton()
        testButton.translatesAutoresizingMaskIntoConstraints = false
        testButton.layer.masksToBounds = false
        testButton.layer.cornerRadius = 15
        testButton.backgroundColor = .systemRed
        testButton.addTarget(self, action: #selector(markAllEventsUnseen), for: .touchUpInside)
        tabBar.addSubview(testButton)
        print("TEsting button added")
        NSLayoutConstraint.activate([
            testButton.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor, constant: 5),
            testButton.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor, constant: -5),
            testButton.heightAnchor.constraint(equalToConstant: 30),
            testButton.widthAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    @objc private func markAllEventsUnseen() {
        ActivityService.shared.updateActivityEventsSeenStatusToFalse(events: self.events) {
            print("Marked all events as unseen")
        }
    }
}

extension TabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        if let navigationController = viewController as? UINavigationController,
           navigationController.viewControllers.contains(where: {$0 is CameraRollViewController}) {
            
            let vc = UINavigationController(rootViewController: CameraRollViewController())
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
                    vc.setTopTableViewVisibleContent()
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
        print("refreshUserprofile called inside tab bar")
        userProfileVC.refreshProfileData()
    }
    
    @objc func refreshUserFeed() {
        homeVC.tableView.refreshUserFeed()
    }
}

extension TabBarController: ActivityViewUnseenEventsProtocol {
    func userHasSeenAllActivityEvents() {
        self.removeNotificationBadge()
    }
}

extension TabBarController: NewPostProtocol {
    func shouldUpdateHomeFeed() {
        print("should update feed")
        homeVC.tableView.refreshUserFeed()
    }
    
    func shouldUpdateUserProfilePosts() {
        print("should update userProfile")
        userProfileVC.refreshProfileData()
    }
    
    
}
