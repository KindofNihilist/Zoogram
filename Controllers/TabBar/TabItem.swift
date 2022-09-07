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
        case .home: return UIImage(systemName: "house")!
        case .discover: return UIImage(systemName: "magnifyingglass")!
        case .makeAPost: return UIImage(systemName: "plus")!
        case .activity: return UIImage(systemName: "heart")!
        case .myProfile: return UIImage(systemName: "person.crop.circle")!
        }
    }
    
    var selectedIcon: UIImage {
        switch self {
        case .home: return UIImage(systemName: "house.fill")!
        case .discover: return UIImage(systemName: "magnifyingglass")!
        case .makeAPost: return UIImage(systemName: "plus")!
        case .activity: return UIImage(systemName: "heart.fill")!
        case .myProfile: return UIImage(systemName: "person.crop.circle.fill")!
        }
    }
}
