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
    
    private var userData: User
    
    override func viewWillAppear(_ animated: Bool) {
        loadTabBar(with: userData)
    }
    
    init(userData: User) {
        self.userData = userData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override func viewDidLoad() {
        delegate = self
//        self.navigationController?.navigationBar.prefersLargeTitles = false
    }
    
//    private func handleNotAuthenticated() {
//        //Check authentication status
//        if Auth.auth().currentUser == nil {
//            //Show log in
//            print("not authenticated")
//            let loginViewController = LoginViewController()
//            loginViewController.modalPresentationStyle = .fullScreen
//        }
//    }

    func loadTabBar(with data: User) {
        let tabItems: [UIViewController] = [HomeViewController(), DiscoverViewController(), NewPostViewController(), ActivityViewController(), ProfileViewController(user: data)]
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
