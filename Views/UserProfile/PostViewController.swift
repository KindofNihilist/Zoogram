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
        
    private let tableView: PostsTableView
    
    init(posts: [PostViewModel], service: PostsService) {
        self.postToFocusOn = IndexPath(row: 0, section: 0)
        self.tableView = PostsTableView(service: service)
        self.tableView.allowsSelection = false
        self.tableView.separatorStyle = .none
        self.tableView.isPaginationAllowed = false
        super.init(nibName: nil, bundle: nil)
        view = tableView
        tableView.insertUserPostsViewModels(postsViewModels: posts)
        tableView.postsTableDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
    
    override func viewDidLayoutSubviews() {
//        tableView.scrollToRow(at: postToFocusOn, at: .top, animated: false)
    }
    
    func updatePostsArrayWith(posts: [PostViewModel]) {
        self.tableView.insertUserPostsViewModels(postsViewModels: posts)
    }
    
    func focusTableViewOnPostWith(index: IndexPath) {
        
        print("Index to focus on: ", index)
//        self.postToFocusOn = IndexPath(row: index.row, section: 0)
        tableView.scrollToRow(at: IndexPath(row: index.row, section: 0), at: .top, animated: false)
        print(tableView.posts[index.row].postCaption.string)
    }
}

extension PostViewController: PostsTableViewProtocol {
    func didTapCommentButton(viewModel: PostViewModel) {
        let commentsViewController = CommentsTableViewController(viewModel: viewModel)
        commentsViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(commentsViewController, animated: true)
    }
    
    func didSelectUser(userID: String, indexPath: IndexPath) {
        let service = UserProfileServiceAPIAdapter(userID: userID,
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
        
        let shareAction = UIAlertAction(title: "Share", style: .cancel) { _ in
            print("shared post", postModel.postID)
        }
        
        actionSheet.addAction(shareAction)
        present(actionSheet, animated: true)
    }
}
