//
//  SceneDelegate.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//
import FirebaseAuth
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private var shouldListenToAuthenticationStateChanges: Bool = true
    private var tabBarController: TabBarController?

    private func logOut() {
        do {
            try AuthenticationService.shared.signOut()
        } catch {
            print(error)
        }
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = Colors.background
//        window?.layer.speed = 0.6

//        logOut()
        setupShouldListenToAuthenticationStateObserver()
        AuthenticationService.shared.listenToAuthenticationState { userID in
            guard self.shouldListenToAuthenticationStateChanges else { return }
            guard let unwrappedID = userID else {
                self.hideCurrentRootViewControllerIfNeeded {
                    self.showLoginView(for: windowScene)
                }
                return
            }
            Task {
                await UserManager.shared.setUserID(uid: unwrappedID)
            }
            let zoogramUser = ZoogramUser(unwrappedID)
            self.tabBarController = TabBarController(for: zoogramUser, showAppearAnimation: false)
            self.window?.windowScene = windowScene
            self.window?.rootViewController = self.tabBarController
            self.window?.makeKeyAndVisible()
        }
    }

    private func setupShouldListenToAuthenticationStateObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(changeShouldListenToAuthenticationState),
            name: .shouldListenToAuthenticationState,
            object: nil)
    }

    @objc private func changeShouldListenToAuthenticationState(_ notification: Notification) {
        guard let shouldListen = notification.userInfo?["shouldListen"] as? Bool else { return }
        self.shouldListenToAuthenticationStateChanges = shouldListen
    }

    private func hideCurrentRootViewControllerIfNeeded(completion: @escaping () -> Void) {
        if let rootViewController = window?.rootViewController {
            rootViewController.hideUIElements(animate: true) {
                completion()
            }
        } else {
            completion()
        }
    }

    private func showLoginView(for windowScene: UIWindowScene, error: Error? = nil) {
        let service = LoginService()
        let loginViewController = LoginViewController(service: service)
        loginViewController.shouldShowOnAppearAnimation = true
        self.shouldListenToAuthenticationStateChanges = false
        let navigationController = UINavigationController(rootViewController: loginViewController)
        navigationController.navigationBar.backgroundColor = Colors.background
        navigationController.navigationBar.isTranslucent = false
        navigationController.tabBarController?.tabBar.isTranslucent = false
        navigationController.tabBarController?.tabBar.backgroundColor = Colors.background
        window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()
        self.window?.windowScene = windowScene
        if let error = error {
            navigationController.show(error: error)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}
