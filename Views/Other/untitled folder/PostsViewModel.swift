//
//  PostViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 18.10.2022.
//

import UIKit

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
    
    var postsModels = [PostModel]()
    
//    func getUserInfo(for userUID: String, completion: @escaping (String, String, Bool, FollowStatus) -> Void) {
//
//        UserService.shared.getUser(for: userUID) { user in
//            user.checkIfFollowedByCurrentUser {
//                completion(user.username, user.profilePhotoURL, user.isUserProfile, user.isFollowed)
//            }
//        }
//    }
    
    func configurePostViewModels(from userPosts: [UserPost], completion: @escaping () -> Void = {}) {
        guard userPosts.isEmpty != true else {
            return
        }
        
        self.userPosts.append(contentsOf: userPosts)
        
        let dispatchGroup = DispatchGroup()
        
        if isAFeed {
            for post in userPosts {
                dispatchGroup.enter()
                UserService.shared.getUser(for: post.userID) { postAuthor in
                    self.createPostViewModel(for: post, author: postAuthor)
                    dispatchGroup.leave()
                }
            }
        } else {
            dispatchGroup.enter()
            UserService.shared.getUser(for: userPosts[0].userID) { postAuthor in
                for post in userPosts {
                    self.createPostViewModel(for: post, author: postAuthor)
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }
    
    func createPostViewModel(for post: UserPost, author: ZoogramUser) {
        var postView = [PostSubviewType]()
        postView.append(PostSubviewType.header(profilePictureURL: author.profilePhotoURL, username: author.username))
        postView.append(PostSubviewType.postContent(provider: post))
        postView.append(PostSubviewType.actions(provider: ""))
        postView.append(PostSubviewType.footer(provider: post, username: author.username))
        self.postsModels.append(PostModel(subviews: postView))
    }
    
    func deletePost(id: String, at sectionIndex: Int, completion: @escaping () -> Void) {
        UserPostService.shared.deletePost(id: id) {
            self.userPosts.remove(at: sectionIndex)
            self.postsModels.remove(at: sectionIndex)
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
    
    func getLikesForPost(id: String, completion: @escaping (Int) -> Void) {
        LikeSystemService.shared.getLikesCountForPost(id: id) { count in
            completion(count)
        }
    }
}

