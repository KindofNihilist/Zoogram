//
//  PostViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 20.01.2022.
//
import SDWebImage
import UIKit


class PostViewController: UIViewController {
    
    private var postToFocusOn: IndexPath
    
    private var posts = [PostViewModel]()
    
    private let tableView: PostsTableView = {
        let tableView = PostsTableView(service: UserPostsAPIServiceAdapter())
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        return tableView
    }()
    
    init(posts: [PostViewModel]) {
        self.postToFocusOn = IndexPath(row: 0, section: 0)
        self.posts = posts
        super.init(nibName: nil, bundle: nil)
        view = tableView
        tableView.postsTableDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
    
    func focusTableViewOnPostWith(index: IndexPath) {
        print("Index to focus on: ", index)
        tableView.scrollToRow(at: IndexPath(row: index.row, section: 0), at: .top, animated: false)
    }
}

extension PostViewController: PostsTableViewProtocol {
    func didTapCommentButton(viewModel: PostViewModel) {
        let commentsViewController = CommentsTableViewController(viewModel: viewModel)
        commentsViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(commentsViewController, animated: true)
    }
    
    func didSelectUser(userID: String, indexPath: IndexPath) {
        let post = posts[indexPath.row]
        let userProfileVC = UserProfileViewController(isTabBarItem: false)
        self.navigationController?.pushViewController(userProfileVC, animated: true)
    }
    
    func didTapMenuButton(postID: String, indexPath: IndexPath) {
        let post = posts[indexPath.row]
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.backgroundColor = .systemBackground
        actionSheet.view.layer.masksToBounds = true
        actionSheet.view.layer.cornerRadius = 15
        
        if post.isMadeByCurrentUser {
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                self?.tableView.deletePost(post: post, indexPath: indexPath)
            }
            actionSheet.addAction(deleteAction)
        }
        
        let shareAction = UIAlertAction(title: "Share", style: .cancel) { _ in
            print("shared post", postID)
        }
        
        actionSheet.addAction(shareAction)
        present(actionSheet, animated: true)
    }
}
