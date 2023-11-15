//
//  UIViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 01.11.2023.
//

import UIKit.UIViewController

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
//        commentsViewController.view.backgroundColor = .systemBackground
        navigationController?.pushViewController(commentsViewController, animated: true)
    }
}
