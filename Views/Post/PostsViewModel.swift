//
//  PostViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 18.10.2022.
//

import UIKit
import SDWebImage

enum PostSubviewType {
    case header(profilePictureURL: String, username: String)
    case postContent(provider: UserPost)
    case actions(provider: String)
    case comment(comment: PostComment)
    case footer(provider: UserPost, username: String)
}

struct PostModel {
    let subviews: [PostSubviewType]
}

class PostsTableViewViewModel {
    
    var isAFeed = false
    
    var userPosts = [UserPost]()
    
    func setupPosts(from userPosts: [UserPost], completion: @escaping () -> Void) {
        guard userPosts.isEmpty != true else {
            return
        }
        
        let dispatchGroup = DispatchGroup()
        
        if isAFeed {
            for post in userPosts {
                dispatchGroup.enter()
                UserService.shared.getUser(for: post.userID) { postAuthor in
                    post.author = postAuthor
                    dispatchGroup.leave()
                }
            }
        } else {
            dispatchGroup.enter()
            UserService.shared.getUser(for: userPosts[0].userID) { postAuthor in
                for post in userPosts {
                    post.author = postAuthor
                }
                dispatchGroup.leave()
            }
        }
        
        for post in userPosts {
            dispatchGroup.enter()
            SDWebImageManager.shared.loadImage(with: URL(string: post.photoURL), progress: .none) { image, data, error, _, _, _ in
                if let downloadedImage = image {
                    post.image = downloadedImage
                }
                dispatchGroup.leave()
            }
//            dispatchGroup.enter()
//            LikeSystemService.shared.getLikesCountForPost(id: post.postID) { likeCount in
//                post.likeCount = likeCount
//                dispatchGroup.leave()
//            }
//            dispatchGroup.enter()
//            post.checkIfLikedByCurrentUser { likeState in
//                post.likeState = likeState
//                dispatchGroup.leave()
//            }
        }
        
//        for post in userPosts {
//            dispatchGroup.enter()
//            LikeSystemService.shared.getLikesCountForPost(id: post.postID) { likeCount in
//                post.likeCount = likeCount
//                dispatchGroup.leave()
//            }
//        }
        
        dispatchGroup.notify(queue: .main) {
            self.userPosts.append(contentsOf: userPosts)
            completion()
        }
    }
    
    func getLikesForPost(id: String, completion: @escaping (Int) -> Void) {
        LikeSystemService.shared.getLikesCountForPost(id: id) { likesCount in
            completion(likesCount)
        }
    }
    
//    func createPostViewModel(for post: UserPost, author: ZoogramUser) {
//        var postView = [PostSubviewType]()
//        postView.append(PostSubviewType.header(profilePictureURL: author.profilePhotoURL, username: author.username))
//        postView.append(PostSubviewType.postContent(provider: post))
//        postView.append(PostSubviewType.actions(provider: ""))
//        postView.append(PostSubviewType.footer(provider: post, username: author.username))
//        self.postsModels.append(PostModel(subviews: postView))
//    }
    
    func deletePost(id: String, at sectionIndex: Int, completion: @escaping () -> Void) {
        UserPostService.shared.deletePost(id: id) {
            self.userPosts.remove(at: sectionIndex)
            NotificationCenter.default.post(name: Notification.Name("PostDeleted"), object: sectionIndex)
            completion()
        }
    }
    
    func likePost(postID: String, completion: @escaping (PostLikeState) -> Void) {
        LikeSystemService.shared.checkIfPostIsLiked(postID: postID) { likeState in
            
            switch likeState {
            case .liked:
                LikeSystemService.shared.removePostLike(postID: postID) { result in
                    switch result {
                    case .success(let description):
                        print(description)
                        completion(.notLiked)
                    case .failure(let error):
                        print(error)
                        completion(.liked)
                    }
                }
            case .notLiked:
                LikeSystemService.shared.likePost(postID: postID) { result in
                    switch result {
                    case .success(let description):
                        print(description)
                        completion(.liked)
                    case .failure(let error):
                        print(error)
                        completion(.notLiked)
                    }
                }
            }
        }
    }
    
//    func getLikesForPost(id: String, completion: @escaping (Int) -> Void) {
//        LikeSystemService.shared.getLikesCountForPost(id: id) { count in
//            completion(count)
//        }
//    }
}

