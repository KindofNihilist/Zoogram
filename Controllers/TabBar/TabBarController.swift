//
//  TabBarController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//

import FirebaseAuth
import UIKit

class TabBarController: UITabBarController {
    
    var tabBarHeight: CGFloat = 55
    
    override func viewWillAppear(_ animated: Bool) {
        loadTabBar()
    }

    override func viewDidLoad() {
        delegate = self
    }

    func loadTabBar() {
        let tabItems: [UIViewController] = [HomeViewController(), DiscoverViewController(), NewPostViewController(), ActivityViewController(), UserProfileViewController(for: AuthenticationManager.shared.getCurrentUserUID())]
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
        tabBar.isTranslucent = false
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
    
}

extension TabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let navigationController = viewController as? UINavigationController,
           navigationController.viewControllers.contains(where: {$0 is NewPostViewController}) {
            let vc = UINavigationController(rootViewController: NewPostViewController())
            vc.modalPresentationStyle = .fullScreen
            vc.navigationBar.isTranslucent = false
            vc.navigationBar.configureNavigationBarColor(with: .black)
            vc.navigationBar.barStyle = .black
            present(vc, animated: true)
            return false
        } else {
            return true
        }
    }
}
