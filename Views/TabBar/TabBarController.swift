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
    
    private func animateAppearing() {
        UIView.animate(withDuration: 0.6) {
            self.view.alpha = 1
            self.view.transform = CGAffineTransform.identity
        }
    }
    
}

extension TabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        if let navigationController = viewController as? UINavigationController,
           navigationController.viewControllers.contains(where: {$0 is NewPostViewController}) {
            
            let vc = UINavigationController(rootViewController: NewPostViewController())
            vc.modalPresentationStyle = .fullScreen
//            vc.navigationBar.isTranslucent = true
//            vc.navigationBar.configureNavigationBarColor(with: .black)
//            vc.navigationBar.barStyle = .black
            present(vc, animated: true)
            return false
        } else {
            return true
        }
    }
}
