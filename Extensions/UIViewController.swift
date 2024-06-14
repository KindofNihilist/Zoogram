//
//  UIViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 01.11.2023.
//

import UIKit.UIViewController

extension UIViewController {

    func hasBottomSafeArea() -> Bool {
        guard let window = UIApplication
            .shared
            .connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .last
        else {
            return false
        }
        let safeAreaLayoutGuide = window.safeAreaLayoutGuide
        let layoutGuideHeight = safeAreaLayoutGuide.layoutFrame.maxY
        let viewHeight = view.frame.maxY
        let heightDifference = viewHeight - layoutGuideHeight
        return heightDifference > 0
    }

    func hideUIElements(animate: Bool, completion: @escaping () -> Void = {}) {
        let duration = animate == true ? 0.5 : 0.0
        UIView.animate(withDuration: duration) {
            self.view.alpha = 0
            self.navigationController?.navigationBar.alpha = 0
        } completion: { _ in
            completion()
        }
    }

    func showUIElements(animate: Bool, completion: @escaping () -> Void = {}) {
        let duration = animate == true ? 0.5 : 0.0
        UIView.animate(withDuration: duration) {
            self.view.alpha = 1
            self.navigationController?.navigationBar.alpha = 1
        } completion: { _ in
            completion()
        }
    }

    func show(error: Error, title: String = "Error") {
        let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true)
    }

    func showProfile(of user: ZoogramUser) {
        let service = UserProfileService(
            userID: user.userID,
            followService: FollowSystemService.shared,
            userPostsService: UserPostsService.shared,
            userService: UserDataService(),
            likeSystemService: LikeSystemService.shared,
            bookmarksService: BookmarksSystemService.shared)

        let userProfileVC = UserProfileViewController(service: service, user: user, isTabBarItem: false)
        userProfileVC.title = user.username
        show(userProfileVC, sender: self)
    }

    func showMenuForPost(postViewModel: PostViewModel, onDelete: @escaping () -> Void) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.backgroundColor = Colors.background
        actionSheet.view.layer.masksToBounds = true
        actionSheet.view.layer.cornerRadius = 15

        if postViewModel.isMadeByCurrentUser {
            let deleteAction = UIAlertAction(title: String(localized: "Delete"), style: .destructive) { _ in
                onDelete()
            }
            actionSheet.addAction(deleteAction)
        }

        let cancelAction = UIAlertAction(title: String(localized: "Cancel"), style: .cancel)
        actionSheet.addAction(cancelAction)

        present(actionSheet, animated: true)
    }

    func showCommentsFor(_ viewModel: PostViewModel) {
        let service = CommentsService(
            postID: viewModel.postID,
            postAuthorID: viewModel.author.userID,
            userDataService: UserDataService(),
            postsService: UserPostsService.shared,
            commentsService: CommentSystemService.shared,
            likesService: LikeSystemService.shared,
            bookmarksService: BookmarksSystemService.shared)
        let commentsViewController = CommentsViewController(
            postViewModel: viewModel,
            shouldShowRelatedPost: false,
            service: service)
        commentsViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(commentsViewController, animated: true)
    }

    func displayNotificationToUser(title: String, text: String, prefferedStyle: UIAlertController.Style, action: ((UIAlertAction) -> Void)?) {
        let alert = UIAlertController(title: title, message: text, preferredStyle: prefferedStyle)
        if let action = action {
            let alertAction = UIAlertAction(title: String(localized: "Ok"), style: .default, handler: action)
            alert.addAction(alertAction)
        } else {
            alert.addAction(UIAlertAction(title: String(localized: "Ok"), style: .default))
        }
        alert.view.backgroundColor = .secondarySystemBackground
        alert.view.layer.cornerRadius = 15
        alert.view.layer.cornerCurve = .continuous
        self.present(alert, animated: true)
    }

    func setupEdditingInteruptionGestures() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        tapGestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGestureRecognizer)
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        swipeGestureRecognizer.cancelsTouchesInView = false
        swipeGestureRecognizer.direction = .down
        view.addGestureRecognizer(swipeGestureRecognizer)
    }
}

extension UIAlertController {
    @objc func dismissSelf() {
        self.dismiss(animated: true)
    }
}
