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
    func didTapMenuButton(postID: String, indexPath: IndexPath)
    func paginateMorePosts(completion: @escaping () -> Void)
    func refreshUserFeed()
}

extension PostsTableViewProtocol {
    func paginateMorePosts(completion: @escaping() -> Void) {}
    func refreshUserFeed() {}
}

class PostsTableView: UITableView {
    
    private var posts = [PostViewModel]() {
        didSet {
            self.reloadData()
        }
    }
    
    var service: PostsService!
    
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
        setupRefreshControl()
        self.dataSource = self
        self.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToWindow() {
        print("inside did move to window")
        guard self.posts.isEmpty == true else {
            return
        }
        print("inside guard")
        service.getPosts { retrievedPosts in
            print("Got posts")
            self.posts = retrievedPosts
            self.refreshControl?.endRefreshing()
        }
    }
    
    func deletePost(post: PostViewModel, indexPath: IndexPath) {
        self.service.deletePost(post: post, at: indexPath) {
            self.deleteRows(at: [indexPath], with: .fade)
//            self.reloadData()
        }
    }
    
    func setupRefreshControl() {
        feedRefreshControl = UIRefreshControl()
        feedRefreshControl?.addTarget(self, action: #selector(refreshUserFeed), for: .valueChanged)
        self.refreshControl = feedRefreshControl
        refreshControl?.beginRefreshing()
    }
    
    func stopRefreshingTheFeed() {
        print("Stop refreshing the feed is called")
        self.refreshControl?.endRefreshing()
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
    
    @objc func refreshUserFeed() {
        service.getPosts { posts in
            self.posts.append(contentsOf: posts)
            self.refreshControl?.endRefreshing()
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
        guard service.hasHitTheEndOfPosts != true else {
            return
        }
        let position = scrollView.contentOffset.y
        
        if position > (self.contentSize.height - 100 - scrollView.frame.size.height) {
            self.tableFooterView = createFooterSpinnerView()
            self.service.getMorePosts { retrievedPosts in
                print("inside scrollViewDidScroll getMorePosts")
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
        self.service.likePost(postID: post.postID, likeState: post.likeState ,postAuthorID: post.authorID) { likeState in
            completion(likeState)
        }
    }
    
    func didTapBookmarkButton(postIndex: IndexPath, completion: @escaping (BookmarkState) -> Void) {
        let post = posts[postIndex.row]
    
        switch post.bookmarkState {
        case .bookmarked:
            self.service.removeBookmark(postID: post.postID)
        case .notBookmarked:
            self.service.bookmarkPost(postID: post.postID, authorID: post.authorID)
        }
    }
    
    func menuButtonTapped(postIndex: IndexPath) {
        let postID = posts[postIndex.row].postID
        postsTableDelegate?.didTapMenuButton(postID: postID, indexPath: postIndex)
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
