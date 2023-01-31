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
    
    private let viewModel = HomeViewModel()
    
    let tableView: PostsTableView = {
        let tableView = PostsTableView()
        tableView.register(PostContentTableViewCell.self, forCellReuseIdentifier: PostContentTableViewCell.identifier)
        tableView.register(PostHeaderTableViewCell.self, forCellReuseIdentifier: PostHeaderTableViewCell.identifier)
        tableView.register(PostActionsTableViewCell.self, forCellReuseIdentifier: PostActionsTableViewCell.identifier)
        tableView.register(PostCommentsTableViewCell.self, forCellReuseIdentifier: PostCommentsTableViewCell.identifier)
        tableView.register(PostFooterTableViewCell.self, forCellReuseIdentifier: PostFooterTableViewCell.identifier)
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        return tableView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view = tableView
        setNavigationBarTitle()
        tableView.postsTableDelegate = self
        view.backgroundColor = .systemBackground
        print("Loading HomeViewController")
        viewModel.getUserFeedPosts { posts in
//            self.bindValues()
            self.tableView.setupFor(posts: posts, isAFeed: true)
            print("Got user feed posts")
        }
    }
    
    
//    func bindValues() {
//        viewModel.posts.bind { userPosts in
//            guard let posts = userPosts else {
//                return
//            }
//
//        }
//    }
    
    func setNavigationBarTitle() {
        
        let navigationBarTitleLabel = UILabel()
        navigationBarTitleLabel.text = "Zoogram"
        navigationBarTitleLabel.font = UIFont(name: "Noteworthy-Bold", size: 24)
        navigationBarTitleLabel.sizeToFit()
//        navigationBarTitleLabel.translatesAutoresizingMaskIntoConstraints = false
//        navigationController?.navigationBar.addSubview(navigationBarTitleLabel)
//
//        if UIDevice.current.hasNotch {
//            print("has notch")
//            navigationBarTitleLabel.topAnchor.constraint(equalTo: (navigationController?.navigationBar.topAnchor)!).isActive = true
//            navigationBarTitleLabel.leadingAnchor.constraint(equalTo: (navigationController?.navigationBar.leadingAnchor)!, constant: 20).isActive = true
//        } else {
//            print("doesn't have notch")
//            navigationBarTitleLabel.centerYAnchor.constraint(equalTo: (navigationController?.navigationBar.centerYAnchor)!).isActive = true
//            navigationBarTitleLabel.leadingAnchor.constraint(equalTo: (navigationController?.navigationBar.leadingAnchor)!, constant: 20).isActive = true
//        }
        
        
        
        
        let leftItem = UIBarButtonItem(customView: navigationBarTitleLabel)
        navigationItem.leftBarButtonItem = leftItem
        
//        let attributes = [NSAttributedString.Key.font: UIFont(name: "Noteworthy-Bold", size: 18)!]
//        navigationController?.navigationBar.standardAppearance.titleTextAttributes = attributes
    }
    
    func focusTableViewOnPostWith(index: IndexPath) {
        tableView.scrollToRow(at: index, at: .top, animated: false)
    }
    
    func setTopTableViewVisibleContent() {
        tableView.setContentOffset(CGPointZero, animated: true)
    }
}

extension HomeViewController: PostsTableViewProtocol {
    func didTapCommentButton(post: UserPost) {
        let commentsViewController = CommentsTableViewController()
        commentsViewController.hidesBottomBarWhenPushed = true
        print(post.caption)
        navigationController?.pushViewController(commentsViewController, animated: true)
    }
    
    func didSelectUser(userID: String, index: Int) {
        guard let post = viewModel.posts.value?[index] else {
            return
        }
        let userProfileVC = UserProfileViewController(for: post.userID, isUserProfile: post.isMadeByCurrentUser(), isFollowed: post.author.isFollowed )
        self.navigationController?.pushViewController(userProfileVC, animated: true)
    }
    
    func didTapMenuButton(postID: String, index: Int) {
        guard let post = viewModel.posts.value?[index] else {
            return
        }
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.backgroundColor = .systemBackground
        actionSheet.view.layer.masksToBounds = true
        actionSheet.view.layer.cornerRadius = 15
        
        if post.isMadeByCurrentUser() {
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                self?.tableView.deletePost(postID: postID, index: index)
            }
            actionSheet.addAction(deleteAction)
        }
        
        let shareAction = UIAlertAction(title: "Share", style: .cancel) { [weak self] _ in
            print("shared post", postID)
        }
        
        actionSheet.addAction(shareAction)
        present(actionSheet, animated: true)
    }
    
    
    
    func refreshUserFeed() {
        viewModel.refreshTheFeed { posts in
            self.tableView.setupFor(posts: posts, isAFeed: true)
            self.tableView.stopRefreshingTheFeed()
        }
    }
    
    func paginateMorePosts() {
        guard !viewModel.isPaginating else {
            print("already paginating")
            return
        }
        
        viewModel.getMoreUserFeedPosts { feedPosts in
            print("Fetched more feed posts")
            self.tableView.addPaginatedUserPosts(posts: feedPosts)
        }
    }
}


