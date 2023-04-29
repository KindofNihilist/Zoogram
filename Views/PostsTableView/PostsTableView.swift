//
//  PostsTableView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.12.2022.
//

import UIKit
import SDWebImage

protocol PostsTableViewProtocol: AnyObject {
    func didTapCommentButton(viewModel: PostViewModel)
    func didSelectUser(userID: String, indexPath: IndexPath)
    func didTapMenuButton(postModel: PostViewModel, indexPath: IndexPath)
}

class PostsTableView: UITableView {
    
    var posts = [PostViewModel]()
    
    var service: PostsService!
    
    var noPostsNotificationView: PlaceholderView?
    
    var isPaginationAllowed: Bool = true
    
    weak var postsTableDelegate: PostsTableViewProtocol?
    
    var feedRefreshControl: UIRefreshControl?
    
    convenience init(service: PostsService, posts: [PostViewModel] = [PostViewModel]()) {
        self.init(frame: CGRect.zero)
        self.posts = posts
        self.service = service
    }
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
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

    
    func insertUserPostsViewModels(postsViewModels: [PostViewModel]) {
        self.posts = postsViewModels
        self.reloadData()
    }
    
    func deletePost(at indexPath: IndexPath) {
        let postModel = posts[indexPath.row]
        print("delete post method triggered")
        self.service.deletePost(postModel: postModel) {
            print("inside deletePost closure")
            self.posts.remove(at: indexPath.row)
            self.deleteRows(at: [indexPath], with: .fade)
            sendNotificationToUpdateUserFeed()
            sendNotificationToUpdateUserProfile()
        }
    }
    
    func setupRefreshControl() {
        feedRefreshControl = UIRefreshControl()
        feedRefreshControl?.addTarget(self, action: #selector(refreshUserFeed), for: .valueChanged)
        self.refreshControl = feedRefreshControl
        refreshControl?.beginRefreshing()
    }
    
    func createFooterSpinnerView() -> UIView {
        guard posts.isEmpty != true else {
            return UIView()
        }
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 100))
        let spinner = UIActivityIndicatorView(style: .medium)
        footerView.addSubview(spinner)
        spinner.center = footerView.center
        spinner.startAnimating()
        return footerView
    }
    
    func showNoPostsNotification() {
        noPostsNotificationView = PlaceholderView(imageName: "camera", text: "New posts of people you follow will be displayed here")
        noPostsNotificationView?.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(noPostsNotificationView!)
        NSLayoutConstraint.activate([
            noPostsNotificationView!.heightAnchor.constraint(equalToConstant: 250),
            noPostsNotificationView!.widthAnchor.constraint(equalTo: self.widthAnchor),
            noPostsNotificationView!.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -20)
        ])
    }
    
    func removeNoPostsNotificationIfDisplayed() {
        if noPostsNotificationView != nil {
            noPostsNotificationView?.removeFromSuperview()
        }
    }
    
    @objc func refreshUserFeed() {
        service.getPosts { posts in
            guard posts.isEmpty != true else {
                self.posts = posts
                self.reloadData()
                self.refreshControl?.endRefreshing()
                self.showNoPostsNotification()
                return
            }
            self.posts = posts
            self.refreshControl?.endRefreshing()
            self.removeNoPostsNotificationIfDisplayed()
            self.reloadData()
        }
    }
}

extension PostsTableView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostTableViewCell.identifier, for: indexPath) as! PostTableViewCell
        
        let post = posts[indexPath.row]
        cell.delegate = self
        cell.configure(with: post, for: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard service.hasHitTheEndOfPosts != true && self.isPaginationAllowed else {
            return
        }
        let position = scrollView.contentOffset.y
        
        if position > (self.contentSize.height - 100 - scrollView.frame.size.height) {
            self.tableFooterView = createFooterSpinnerView()
        
            self.service.getMorePosts { retrievedPosts in
                self.posts.append(contentsOf: retrievedPosts)
                self.tableFooterView = nil
                self.reloadData()
            }
        }
    }
}

//extension PostsTableView: UITableViewDataSourcePrefetching {
//
//    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
//        print("PREFETCHING DATA")
//        indexPaths.forEach { indexPath in
//            let photoURL = self.viewModel.userPosts[indexPath.section].photoURL
//            SDWebImageManager.shared.loadImage(with: URL(string: photoURL), progress: .none) { image, data, error, cache, _, _ in
//                guard let downloadedImage = image else {
//                    return
//                }
//                self.viewModel.userPosts[indexPath.section].image = downloaded  Image
//            }
//        }
//    }
//}

extension PostsTableView: PostTableViewCellProtocol {
    func didTapLikeButton(postIndex: IndexPath, completion: @escaping (LikeState) -> Void) {
        let post = posts[postIndex.row]
        print("like state: \(post.likeState)")
        self.service.likePost(postID: post.postID, likeState: post.likeState ,postAuthorID: post.authorID) { likeState in
            self.posts[postIndex.row].likeState = likeState
            print("completion like state: \(likeState)")
            completion(likeState)
        }
    }
    
    func didTapBookmarkButton(postIndex: IndexPath, completion: @escaping (BookmarkState) -> Void) {
        let post = posts[postIndex.row]
        self.service.bookmarkPost(postID: post.postID, authorID: post.authorID, bookmarkState: post.bookmarkState) { bookmarkState in
            self.posts[postIndex.row].bookmarkState = bookmarkState
            completion(bookmarkState)
        }
    }
    
    func menuButtonTapped(postIndex: IndexPath) {
        let postViewModel = posts[postIndex.row]
        postsTableDelegate?.didTapMenuButton(postModel: postViewModel, indexPath: postIndex)
    }
    
    func didTapPostAuthor(postIndex: IndexPath) {
        let userID = posts[postIndex.row].authorID
        postsTableDelegate?.didSelectUser(userID: userID, indexPath: postIndex)
    }

    
    func didTapCommentButton(postIndex: IndexPath) {
        let viewModel = posts[postIndex.row]
        postsTableDelegate?.didTapCommentButton(viewModel: viewModel)
    }
}
