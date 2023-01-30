//
//  PostsTableView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.12.2022.
//

import UIKit
import SDWebImage

protocol PostsTableViewProtocol: AnyObject {
    func paginateMorePosts()
    func refreshUserFeed()
    func didTapCommentButton(post: UserPost)
    func didSelectUser(userID: String, index: Int)
    func didTapMenuButton(postID: String, index: Int)
}

extension PostsTableViewProtocol {
    func paginateMorePosts() {}
    func refreshUserFeed() {}
}

class PostsTableView: UITableView {
    
    let viewModel = PostsTableViewViewModel()
    
    weak var postsTableDelegate: PostsTableViewProtocol?
    
    let feedRefreshControl = UIRefreshControl()
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
//        register(PostContentTableViewCell.self, forCellReuseIdentifier: PostContentTableViewCell.identifier)
//        register(PostHeaderTableViewCell.self, forCellReuseIdentifier: PostHeaderTableViewCell.identifier)
//        register(PostActionsTableViewCell.self, forCellReuseIdentifier: PostActionsTableViewCell.identifier)
//        register(PostCommentsTableViewCell.self, forCellReuseIdentifier: PostCommentsTableViewCell.identifier)
//        register(PostFooterTableViewCell.self, forCellReuseIdentifier: PostFooterTableViewCell.identifier)
        register(PostTableViewCell.self, forCellReuseIdentifier: PostTableViewCell.identifier)
        allowsSelection = false
        separatorStyle = .none
        rowHeight = UITableView.automaticDimension
        estimatedRowHeight = 300
        self.dataSource = self
        self.delegate = self
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupFor(posts: [UserPost], isAFeed: Bool) {
        if isAFeed {
            setupRefreshControl()
        }
        print("Setup for posts count:", posts.count)
        viewModel.userPosts.removeAll()
        viewModel.isAFeed = isAFeed
        viewModel.setupPosts(from: posts) {
            self.reloadData()
        }
    }
    
    func deletePost(postID: String, index: Int) {
        self.viewModel.deletePost(id: postID, at: index) {
            self.reloadData()
        }
    }
    
    func addPaginatedUserPosts(posts: [UserPost]) {
        viewModel.setupPosts(from: posts) {
            self.reloadData()
        }
    }
    
    func setupRefreshControl() {
        feedRefreshControl.addTarget(self, action: #selector(refreshUserFeed), for: .valueChanged)
        self.refreshControl = feedRefreshControl
    }
    
    func stopRefreshingTheFeed() {
        self.refreshControl?.endRefreshing()
    }
    
    @objc func refreshUserFeed() {
        self.postsTableDelegate?.refreshUserFeed()
    }
    
}

extension PostsTableView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.userPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostTableViewCell.identifier, for: indexPath) as! PostTableViewCell
        
        let post = viewModel.userPosts[indexPath.row]
        cell.delegate = self
        cell.configure(forPost: post, postIndex: indexPath.row)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
////        let post = viewModel.postsModels[indexPath.section]
////        switch post.subviews[indexPath.row] {
////        case .header(_, _): return 50
////        case .postContent(_): return UITableView.automaticDimension
////        case .actions(_): return 45
////        case .footer(_, _): return UITableView.automaticDimension
////        case .comment(_): return 50
////        }
//        return UITableView.automaticDimension
//    }
//
//    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return UITableView.automaticDimension
//    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let position = scrollView.contentOffset.y
        
        if position > (self.contentSize.height - 100 - scrollView.frame.size.height) {
            self.postsTableDelegate?.paginateMorePosts()
            print("Call to paginate more posts")
        }
    }
}

extension PostsTableView: UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        print("PREFETCHING DATA")
        indexPaths.forEach { indexPath in
            let photoURL = self.viewModel.userPosts[indexPath.section].photoURL
            SDWebImageManager.shared.loadImage(with: URL(string: photoURL), progress: .none) { image, data, error, cache, _, _ in
                guard let downloadedImage = image else {
                    return
                }
                self.viewModel.userPosts[indexPath.section].image = downloadedImage
            }
        }
    }
}

extension PostsTableView: PostActionsDelegate {
    func didTapLikeButton(postID: String, postActionsView: PostActionsTableViewCell) {
        viewModel.likePost(postID: postID) { likeState in
            postActionsView.configureLikeButton(likeState: likeState)
        }
    }
    
    func didTapCommentButton() {
        return
    }
    
    func didTapBookmarkButton() {
        return
    }
}

extension PostsTableView: PostTableViewCellProtocol {
    func didTapCommentButton(post: UserPost) {
        postsTableDelegate?.didTapCommentButton(post: post)
    }
    
    func didSelectUser(userID: String, atIndex: Int) {
        postsTableDelegate?.didSelectUser(userID: userID, index: atIndex)
    }
    
    func menuButtonTapped(forPost: String, atIndex: Int) {
        postsTableDelegate?.didTapMenuButton(postID: forPost, index: atIndex)
    }
    
    func didTapLikeButton(postID: String, postActionsCell: PostTableViewCell) {
        viewModel.likePost(postID: postID) { likeState in
            postActionsCell.configureLikeButton(likeState: likeState)
        }
    }
}
