//
//  Extensions.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 18.01.2022.
//

import UIKit
import SwiftUI

extension Date {
    func timeAgoDisplay() -> String {
        let secondsAgo = Int(Date().timeIntervalSince(self))

        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day
        let month = 4 * week

        let quotient: Int
        let unit: String
        if secondsAgo < minute {
            quotient = secondsAgo
            unit = "second"
        } else if secondsAgo < hour {
            quotient = secondsAgo / minute
            unit = "min"
        } else if secondsAgo < day {
            quotient = secondsAgo / hour
            unit = "hour"
        } else if secondsAgo < week {
            quotient = secondsAgo / day
            unit = "day"
        } else if secondsAgo < month {
            quotient = secondsAgo / week
            unit = "week"
        } else {
            quotient = secondsAgo / month
            unit = "month"
        }

        return "\(quotient) \(unit)\(quotient == 1 ? "" : "s") ago"

    }
}

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

extension UIView {
    func addSubviews(_ views: UIView...) {
        for view in views {
            addSubview(view)
        }
    }

    func removeSubviews(_ views: UIView...) {
        for view in views {
            view.removeFromSuperview()
        }
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

    func setAndLayoutTableHeaderView(header: UIView) {
        self.tableHeaderView = header
        self.tableHeaderView?.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            header.widthAnchor.constraint(equalTo: self.widthAnchor)
        ])
        header.setNeedsLayout()
        header.layoutIfNeeded()
        header.frame.size = header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        self.tableHeaderView = header
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

extension UIImage {
    func croppedInRect(rect: CGRect) -> UIImage {
        func rad(_ degree: Double) -> CGFloat {
            return CGFloat(degree / 180.0 * .pi)
        }

        var rectTransform: CGAffineTransform
        switch imageOrientation {
        case .left:
            rectTransform = CGAffineTransform(rotationAngle: rad(90)).translatedBy(x: 0, y: -self.size.height)
        case .right:
            rectTransform = CGAffineTransform(rotationAngle: rad(-90)).translatedBy(x: -self.size.width, y: 0)
        case .down:
            rectTransform = CGAffineTransform(rotationAngle: rad(-180)).translatedBy(x: -self.size.width, y: -self.size.height)
        default:
            rectTransform = .identity
        }
        rectTransform = rectTransform.scaledBy(x: self.scale, y: self.scale)

        let imageRef = self.cgImage!.cropping(to: rect.applying(rectTransform))
        let result = UIImage(cgImage: imageRef!, scale: self.scale, orientation: self.imageOrientation)
        return result
    }

    func compressed() -> UIImage? {
        let originalImageSize = NSData(data: self.jpegData(compressionQuality: 1)!).count
        print("Original image size in KB: %f", Double(originalImageSize).rounded())
        let jpegData = self.jpegData(compressionQuality: 1)
        print("Compressed image size in KB: %f", Double(jpegData!.count).rounded())
        let compressedImage = UIImage(data: jpegData!)
        return compressedImage
    }

    func ratio() -> CGFloat {
        return self.size.width / self.size.height
    }

    func isWidthDominant() -> Bool {
        return self.size.width / self.size.height > 1
    }
}

extension UIViewController {
    func show(error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true)
    }

    func showProfile(of user: ZoogramUser) {
        let service = UserProfileServiceAPIAdapter(
            userID: user.userID,
            followService: FollowSystemService.shared,
            userPostsService: UserPostsService.shared,
            userService: UserService.shared,
            likeSystemService: LikeSystemService.shared,
            bookmarksService: BookmarksService.shared)

        let userProfileVC = UserProfileViewController(service: service, user: user, isTabBarItem: false)

        show(userProfileVC, sender: self)
    }

    func showMenuForPost(postViewModel: PostViewModel, onDelete: @escaping () -> Void) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.backgroundColor = .systemBackground
        actionSheet.view.layer.masksToBounds = true
        actionSheet.view.layer.cornerRadius = 15

        if postViewModel.isMadeByCurrentUser {
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
                onDelete()
            }
            actionSheet.addAction(deleteAction)
        }

        let shareAction = UIAlertAction(title: "Share", style: .cancel) { _ in
        }

        actionSheet.addAction(shareAction)
        present(actionSheet, animated: true)
    }

    func showCommentsFor(_ viewModel: PostViewModel) {
        let service = PostWithCommentsServiceAdapter(
            postID: viewModel.postID,
            postAuthorID: viewModel.author.userID,
            postsService: UserPostsService.shared,
            commentsService: CommentSystemService.shared,
            likesService: LikeSystemService.shared,
            bookmarksService: BookmarksService.shared)
        let commentsViewController = CommentsViewController(postViewModel: viewModel, shouldShowRelatedPost: false, service: service)
        commentsViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(commentsViewController, animated: true)
    }
}
