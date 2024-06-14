//
//  AppDelegate.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//
import Firebase
import FirebaseDatabase
import UIKit
import CoreHaptics

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var supportsHaptics: Bool = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let options = FirebaseOptions(googleAppID: "1:862393838316:ios:429315f6903fb724c453c9", gcmSenderID: "862393838316")
        options.databaseURL = "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app"
        options.apiKey = "AIzaSyD311n0IEIRZwm24GW0i0V15WxRk9E9uEE"
        options.projectID = "catogram-58487"

        FirebaseApp.configure(options: options)
        Database.database().isPersistenceEnabled = false

        let hapticCapability = CHHapticEngine.capabilitiesForHardware()
        supportsHaptics = hapticCapability.supportsHaptics
        configureTabBar(with: Colors.background)
        configureNavigationBar(with: Colors.background)
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    private func configureNavigationBar(with color: UIColor) {
        let appearence = UINavigationBarAppearance()
        appearence.configureWithOpaqueBackground()
        appearence.backgroundColor = color
        appearence.shadowColor = .clear
        appearence.titleTextAttributes = [.font: CustomFonts.boldFont(ofSize: 17)]
        UINavigationBar.appearance().standardAppearance = appearence
        UINavigationBar.appearance().scrollEdgeAppearance = appearence
    }
    private func configureTabBar(with color: UIColor) {
        let tabItemAppearence = UITabBarItemAppearance(style: .stacked)
        tabItemAppearence.normal.badgeBackgroundColor = .clear
        tabItemAppearence.normal.badgeTextAttributes = [.foregroundColor: UIColor.systemRed]
        let barAppearence = UITabBarAppearance()
        barAppearence.configureWithDefaultBackground()
        barAppearence.backgroundColor = color
        barAppearence.shadowColor = .clear
        barAppearence.stackedLayoutAppearance = tabItemAppearence
        barAppearence.compactInlineLayoutAppearance = tabItemAppearence
        barAppearence.inlineLayoutAppearance = tabItemAppearence
        UITabBar.appearance().standardAppearance = barAppearence
        UITabBar.appearance().scrollEdgeAppearance = barAppearence
    }
}
