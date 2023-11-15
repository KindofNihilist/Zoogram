//
//  Extensions.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 18.01.2022.
//

import UIKit
import SwiftUI



//extension UIDevice {
//    var hasNotch: Bool {
//            if #available(iOS 13.0, *) {
//                let scenes = UIApplication.shared.connectedScenes
//                let windowScene = scenes.first as? UIWindowScene
//                guard let window = windowScene?.windows.first else { return false }
//
//                return window.safeAreaInsets.top > 20
//            }
//
//            if #available(iOS 11.0, *) {
//                let top = UIApplication.shared.windows[0].safeAreaInsets.top
//                return top > 20
//            } else {
//                return false
//            }
//        }
//}

extension CGFloat {
    func withFractionLength(_ length: Int) -> CGFloat {
        let multiplier = pow(10.0, CGFloat(length))
        return (self * multiplier) / multiplier
    }
}

extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)).flatMap { $0 as? [String: Any]}
    }
}

extension UIFont {
    class func rounded(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        guard #available(iOS 13.0, *), let descriptor = systemFont.fontDescriptor.withDesign(.rounded) else { return systemFont }
        return UIFont(descriptor: descriptor, size: size)
    }
}



extension UIStackView {
    func addArrangedSubviews(_ views: UIView...) {
        for view in views {
            addArrangedSubview(view)
        }
    }
}

extension String {
    func safeDatabaseKey() -> String {
        return self.replacingOccurrences(of: ".", with: "-")
    }

    func lineWithSpacing(_ spacing: CGFloat) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = spacing
        let attributedString = NSAttributedString(string: self, attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        return attributedString
    }
}

extension UICollectionView {
    func dequeue<T: UICollectionViewCell>(withIdentifier identifier: String, for indexPath: IndexPath) -> T {
        guard let cell = self.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? T else {
            fatalError("Could not cast cell")
        }
        return cell
    }

    func dequeueReusableView<T: UICollectionReusableView>(withIdentifier identifier: String, ofKind: String, for indexPath: IndexPath) -> T {
        guard let view = self.dequeueReusableSupplementaryView(ofKind: ofKind, withReuseIdentifier: identifier, for: indexPath) as? T else {
            fatalError("Could not cast reusable view")
        }
        return view
    }
}

extension UITableView {
    func dequeue<T: UITableViewCell>(withIdentifier identifier: String, for indexPath: IndexPath) -> T {
        guard let cell = self.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? T else {
            fatalError("Could not cast cell")
        }
        return cell
    }
}

extension UINavigationBar {
    func configureNavigationBarColor(with color: UIColor) {
        let appearence = UINavigationBarAppearance()
        appearence.configureWithOpaqueBackground()
        appearence.backgroundColor = color
        appearence.shadowColor = .clear
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

extension UIImageView {
    func getOnlyVisiblePartOfImage(image: UIImage, rect: CGRect, scale: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: rect.size.width / scale, height: rect.size.height / scale), true, 0.0)
        image.draw(at: CGPoint(x: -rect.origin.x / scale, y: -rect.origin.y / scale))
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return croppedImage
    }
}
