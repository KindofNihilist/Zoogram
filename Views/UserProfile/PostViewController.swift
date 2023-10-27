//
//  PostViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 20.01.2022.
//
import SDWebImage
import UIKit

protocol UserProfilePostsTableViewProtocol: AnyObject {
    func updateUserProfilePosts()
}

class PostViewController: UIViewController {

    weak var delegate: UserProfilePostsTableViewProtocol?

    private var postToFocusOn: IndexPath

    private let tableView: PostsTableView

    init(posts: [PostViewModel], service: PostsService) {
        self.postToFocusOn = IndexPath(row: 0, section: 0)
        self.tableView = PostsTableView(service: service)
        self.tableView.allowsSelection = false
        self.tableView.separatorStyle = .none
        self.tableView.isPaginationAllowed = false
        super.init(nibName: nil, bundle: nil)
        view = tableView
        tableView.setUserPostsViewModels(postsViewModels: posts)
        tableView.postsTableDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }

    func updatePostsArrayWith(posts: [PostViewModel]) {
        self.tableView.setUserPostsViewModels(postsViewModels: posts)
    }

    func focusTableViewOnPostWith(index: IndexPath) {
        tableView.scrollToRow(at: IndexPath(row: index.row, section: 0), at: .top, animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.tableView.scrollToRow(at: IndexPath(row: index.row, section: 0), at: .top, animated: false)
        }
    }
}

extension PostViewController: PostsTableViewProtocol {
    func didTapCommentButton(viewModel: PostViewModel) {
        showCommentsFor(viewModel)
    }

    func didSelectUser(user: ZoogramUser) {
        let service = UserProfileServiceAPIAdapter(userID: user.userID,
                                                   followService: FollowSystemService.shared,
                                                   userPostsService: UserPostsService.shared,
                                                   userService: UserService.shared,
                                                   likeSystemService: LikeSystemService.shared,
                                                   bookmarksService: BookmarksService.shared)
        let userProfileVC = UserProfileViewController(service: service, user: user, isTabBarItem: false)
        self.navigationController?.pushViewController(userProfileVC, animated: true)
    }

    func didTapMenuButton(postModel: PostViewModel, indexPath: IndexPath) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.backgroundColor = .systemBackground
        actionSheet.view.layer.masksToBounds = true
        actionSheet.view.layer.cornerRadius = 15

        if postModel.isMadeByCurrentUser {
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                self?.tableView.deletePost(at: indexPath) {
                    sendNotificationToUpdateUserProfile()
//                    self?.delegate?.updateUserProfileData()
                    sendNotificationToUpdateUserFeed()
                }
            }
            actionSheet.addAction(deleteAction)
        }

        let shareAction = UIAlertAction(title: "Share", style: .cancel) { _ in
            print("shared post", postModel.postID)
        }

        actionSheet.addAction(shareAction)
        present(actionSheet, animated: true)
    }
}
