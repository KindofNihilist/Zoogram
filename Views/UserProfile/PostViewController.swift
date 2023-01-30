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
    
    private var isUserProfile: Bool
    
    private let tableView: PostsTableView = {
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
    
    init(posts: [UserPost], isUserProfile: Bool) {
        self.isUserProfile = isUserProfile
        self.postToFocusOn = IndexPath(row: 0, section: 0)
        super.init(nibName: nil, bundle: nil)
        view = tableView
        tableView.setupFor(posts: posts, isAFeed: false)
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
    
    func addPaginatedPosts(posts: [UserPost]) {
        tableView.addPaginatedUserPosts(posts: posts)
    }
    
    
}

//
//extension PostViewController: PostDelegate {
//
//    func didSelectUser(userID: String, atIndex: Int) {
//        let postModel = viewModel.postsModels[atIndex]
//        let userProfileVC = UserProfileViewController(for: userID, isUserProfile: postModel.isUserPost, isFollowed: postModel.isFollowed)
//        navigationController?.pushViewController(userProfileVC, animated: true)
//    }
//
//    func menuButtonTappedFor(postID: String, index: Int) {
//        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//        actionSheet.view.backgroundColor = .systemBackground
//        actionSheet.view.layer.masksToBounds = true
//        actionSheet.view.layer.cornerRadius = 15
//        if isUserProfile {
//            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
//                self?.viewModel.deletePost(id: postID, at: index) {
//                    self?.tableView.reloadData()
//                }
//            }
//            actionSheet.addAction(deleteAction)
//        }
//
//        let shareAction = UIAlertAction(title: "Share", style: .cancel) { [weak self] _ in
//            print("shared post", postID)
//        }
//
//        actionSheet.addAction(shareAction)
//        present(actionSheet, animated: true)
//    }
//}
//
//extension PostViewController: PostActionsDelegate {
//    func didTapLikeButton(postID: String, postActionsView: PostActionsTableViewCell) {
//        viewModel.likePost(postID: postID) { likeState in
//            postActionsView.configureLikeButton(likeState: likeState)
//        }
//    }
//
//    func didTapCommentButton() {
//        return
//    }
//
//    func didTapBookmarkButton() {
//        return
//    }
//
//
//}
