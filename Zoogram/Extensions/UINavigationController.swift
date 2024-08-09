//
//  UINavigationController.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 29.12.2023.
//

import UIKit.UINavigationController

extension UINavigationController {
  open override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    navigationBar.topItem?.backButtonDisplayMode = .minimal
  }
}

extension UINavigationBar {
    func configureNavigationBarColor(with color: UIColor) {
        let appearence = UINavigationBarAppearance()
        appearence.configureWithOpaqueBackground()
        appearence.backgroundColor = color
        appearence.shadowColor = .none
        appearence.titleTextAttributes = [.font: CustomFonts.boldFont(ofSize: 17)]
        if color == .black {
            appearence.titleTextAttributes = [.foregroundColor: UIColor.white]
        }
        self.standardAppearance = appearence
        self.scrollEdgeAppearance = appearence
    }
}

extension UITabBar {
    func configureTabBarColor(with color: UIColor) {
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
        self.standardAppearance = barAppearence
        self.scrollEdgeAppearance = barAppearence
    }
}
