//
//  HomeViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//
import SDWebImage
import FirebaseAuth
import UIKit

class HomeViewController: UIViewController {
    
    let tableView: PostsTableView = {
        let service = HomeFeedPostsAPIServiceAdapter(
            homeFeedService: HomeFeedService.shared,
            likeSystemService: LikeSystemService.shared,
            userPostService: UserPostsService.shared,
            bookmarksService: BookmarksService.shared)
        
        let tableView = PostsTableView(service: service)
        tableView.setupRefreshControl()
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        return tableView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view = tableView
        setNavigationBarTitle()
        tableView.postsTableDelegate = self
        tableView.refreshUserFeed()
        view.backgroundColor = .systemBackground
    }
    
    func setNavigationBarTitle() {
        
        let navigationBarTitleLabel = UILabel()
        navigationBarTitleLabel.text = "Zoogram"
        navigationBarTitleLabel.font = UIFont(name: "Noteworthy-Bold", size: 24)
        navigationBarTitleLabel.sizeToFit()
        
        let leftItem = UIBarButtonItem(customView: navigationBarTitleLabel)
        navigationItem.leftBarButtonItem = leftItem
    }
    
    func focusTableViewOnPostWith(index: IndexPath) {
        tableView.scrollToRow(at: index, at: .top, animated: false)
    }
    
    func setTopTableViewVisibleContent() {
        tableView.setContentOffset(CGPointZero, animated: true)
    }
}

extension HomeViewController: PostsTableViewProtocol {
    
    func didTapCommentButton(viewModel: PostViewModel) {
        let commentsViewController = CommentsTableViewController(viewModel: viewModel)
        commentsViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(commentsViewController, animated: true)
    }
    
    func didSelectUser(userID: String, indexPath: IndexPath) {
        let service = UserProfileServiceAPIAdapter(
            userID: userID,
            followService: FollowService.shared,
            userPostsService: UserPostsService.shared,
            userService: UserService.shared,
            likeSystemService: LikeSystemService.shared,
            bookmarksService: BookmarksService.shared)
        
        let userProfileVC = UserProfileViewController(service: service, isTabBarItem: false)
        
        self.navigationController?.pushViewController(userProfileVC, animated: true)
    }
    
    func didTapMenuButton(postModel: PostViewModel, indexPath: IndexPath) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.backgroundColor = .systemBackground
        actionSheet.view.layer.masksToBounds = true
        actionSheet.view.layer.cornerRadius = 15
        
        if postModel.isMadeByCurrentUser {
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                self?.tableView.deletePost(at: indexPath)
            }
            actionSheet.addAction(deleteAction)
        }
        
        let shareAction = UIAlertAction(title: "Share", style: .cancel) { [weak self] _ in
            print("shared post", postModel.postID)
        }
        
        actionSheet.addAction(shareAction)
        present(actionSheet, animated: true)
    }
}


