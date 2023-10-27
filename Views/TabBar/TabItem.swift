//
//  TabItem.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//

import UIKit

enum TabItem: String, CaseIterable {

    case home = "home"
    case discover = "discover"
    case makeAPost = "makeAPost"
    case activity = "activity"
    case myProfile = "myProfile"

    var icon: UIImage {
        switch self {
        case .home: return UIImage(systemName: "house")!.imageWithoutBaseline()
        case .discover: return UIImage(systemName: "magnifyingglass")!.imageWithoutBaseline()
        case .makeAPost: return UIImage(systemName: "plus")!.imageWithoutBaseline()
        case .activity: return UIImage(systemName: "heart")!.imageWithoutBaseline()
        case .myProfile: return UIImage(systemName: "person.crop.circle")!.imageWithoutBaseline()
        }
    }

    var selectedIcon: UIImage {
        switch self {
        case .home: return UIImage(systemName: "house.fill")!.imageWithoutBaseline()
        case .discover: return UIImage(systemName: "magnifyingglass")!.imageWithoutBaseline()
        case .makeAPost: return UIImage(systemName: "plus")!.imageWithoutBaseline()
        case .activity: return UIImage(systemName: "heart.fill")!.imageWithoutBaseline()
        case .myProfile: return UIImage(systemName: "person.crop.circle.fill")!.imageWithoutBaseline()
        }
    }
}
