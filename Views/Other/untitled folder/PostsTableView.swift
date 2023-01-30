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
    func didTapCommentButton()
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
        register(PostContentTableViewCell.self, forCellReuseIdentifier: PostContentTableViewCell.identifier)
        register(PostHeaderTableViewCell.self, forCellReuseIdentifier: PostHeaderTableViewCell.identifier)
        register(PostActionsTableViewCell.self, forCellReuseIdentifier: PostActionsTableViewCell.identifier)
        register(PostCommentsTableViewCell.self, forCellReuseIdentifier: PostCommentsTableViewCell.identifier)
        register(PostFooterTableViewCell.self, forCellReuseIdentifier: PostFooterTableViewCell.identifier)
        allowsSelection = false
        separatorStyle = .none
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
        viewModel.postsModels.removeAll()
        viewModel.isAFeed = isAFeed
        viewModel.configurePostViewModels(from: posts) {
            self.reloadData()
        }
    }
    
    func deletePost(postID: String, index: Int) {
        self.viewModel.deletePost(id: postID, at: index) {
            self.reloadData()
        }
    }
    
    func addPaginatedUserPosts(posts: [UserPost]) {
        viewModel.configurePostViewModels(from: posts) {
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
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.postsModels.count
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let position = scrollView.contentOffset.y
        
        if position > (self.contentSize.height - 100 - scrollView.frame.size.height) {
            self.postsTableDelegate?.paginateMorePosts()
            print("Call to paginate more posts")
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.postsModels[section].subviews.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let postModel = viewModel.postsModels[indexPath.section]
        let post = viewModel.userPosts[indexPath.section]
        
        switch postModel.subviews[indexPath.row] {
            
        case .header(let profilePictureURL, let username):
            let cell = tableView.dequeueReusableCell(withIdentifier: PostHeaderTableViewCell.identifier, for: indexPath) as! PostHeaderTableViewCell
            cell.delegate = self
            cell.configureWith(profilePictureURL: profilePictureURL, username: username, postID: post.postID, userID: post.userID, postIndex: indexPath.section)
            return cell
            
        case .postContent(let post):
            
            let cell = tableView.dequeueReusableCell(withIdentifier: PostContentTableViewCell.identifier, for: indexPath) as! PostContentTableViewCell
            
            if let image = post.image {
                
                cell.configure(with: image)
                
            } else {
                SDWebImageManager.shared.loadImage(with: URL(string: post.photoURL), progress: .none) { image, data, error, _, _, _ in
                    
                    if let downloadedImage = image {
                        cell.configure(with: downloadedImage)
                        self.viewModel.userPosts[indexPath.section].image = downloadedImage
                    }
                }
            }
            return cell
            
        case .actions(_):
            let cell = tableView.dequeueReusableCell(withIdentifier: PostActionsTableViewCell.identifier, for: indexPath) as! PostActionsTableViewCell
            cell.delegate = self
            post.checkIfLikedByCurrentUser { likeState in
                cell.configureLikeButton(likeState: likeState)
            }
            cell.postID = post.postID
            return cell
            
        case .footer(let post, let username):
            let cell = tableView.dequeueReusableCell(withIdentifier: PostFooterTableViewCell.identifier, for: indexPath) as! PostFooterTableViewCell
            cell.configure(for: post, username: username)
            viewModel.getLikesForPost(id: post.postID) { count in
                cell.setLikes(likesCount: count)
            }
            return cell
            
        case .comment(let comment):
            let cell = tableView.dequeueReusableCell(withIdentifier: PostCommentsTableViewCell.identifier, for: indexPath) as! PostCommentsTableViewCell
            cell.configure(with: comment)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let post = viewModel.postsModels[indexPath.section]
        switch post.subviews[indexPath.row] {
        case .header(_, _): return 50
        case .postContent(_): return UITableView.automaticDimension
        case .actions(_): return 45
        case .footer(_, _): return UITableView.automaticDimension
        case .comment(_): return 50
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

extension PostsTableView: PostHeaderDelegate {
    func menuButtonTappedFor(postID: String, index: Int) {
        postsTableDelegate?.didTapMenuButton(postID: postID, index: index)
    }
    
    func didSelectUser(userID: String, atIndex: Int) {
        postsTableDelegate?.didSelectUser(userID: userID, index: atIndex)
    }
}
