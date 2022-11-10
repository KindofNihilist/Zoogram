//
//  PostViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 20.01.2022.
//
import SDWebImage
import UIKit


class PostViewController: UIViewController {
    
    private let viewModel: PostViewModel
    
    private var postToFocusOn: IndexPath
    
    private var isUserProfile: Bool
    
    private let tableView: UITableView = {
        let tableView = UITableView()
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
        self.viewModel = PostViewModel(userPosts: posts)
        super.init(nibName: nil, bundle: nil)
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.prefetchDataSource = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
    
    func focusTableViewOnPostWith(index: IndexPath) {
        tableView.scrollToRow(at: index, at: .top, animated: false)
    }
    
    func addPaginatedUserPosts(posts: [UserPost]) {
        viewModel.userPosts.append(contentsOf: posts)
        viewModel.configurePostViewModels(from: posts) {
            self.tableView.reloadData()
        }
        
    }
}

extension PostViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.postsModels.count
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
            cell.postID = post.postID
            cell.postIndex = indexPath.section
            cell.configureWith(profilePictureURL: profilePictureURL, username: username)
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

extension PostViewController: UITableViewDataSourcePrefetching {
    
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

extension PostViewController: PostHeaderDelegate {
    func menuButtonTappedFor(postID: String, index: Int) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.backgroundColor = .systemBackground
        actionSheet.view.layer.masksToBounds = true
        actionSheet.view.layer.cornerRadius = 15
        if isUserProfile {
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                self?.viewModel.deletePost(id: postID, at: index) {
                    self?.tableView.reloadData()
                }
            }
            actionSheet.addAction(deleteAction)
        }
        
        let shareAction = UIAlertAction(title: "Share", style: .cancel) { [weak self] _ in
            print("shared post", postID)
        }
        
        actionSheet.addAction(shareAction)
        present(actionSheet, animated: true)
    }
}

extension PostViewController: PostActionsDelegate {
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
