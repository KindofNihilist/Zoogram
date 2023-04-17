//
//  PostsService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 08.04.2023.
//

import Foundation
import SDWebImage

protocol PostsService {
    var lastReceivedPostKey: String {get set}
    var isAlreadyPaginating: Bool {get set}
    var hasHitTheEndOfPosts: Bool {get set}
    
    func getPosts(completion: @escaping ([PostViewModel]) -> Void)
    func getMorePosts(completion: @escaping ([PostViewModel]) -> Void)
    func likePost(postID: String, likeState: LikeState, postAuthorID: String, completion: @escaping (LikeState) -> Void)
    func deletePost(post: PostViewModel, at indexPath: IndexPath, completion: @escaping () -> Void)
    func bookmarkPost(postID: String, authorID: String)
    func removeBookmark(postID: String)
}

extension PostsService {
    
    func getAdditionalPostDataFor(postsOfMultipleUsers: [UserPost], completion: @escaping ([UserPost]) -> Void) {
        guard postsOfMultipleUsers.isEmpty != true else {
            completion([UserPost]())
            return
        }
        print("inside get additiona post data method")
        let dispatchGroup = DispatchGroup()
        
        for post in postsOfMultipleUsers {
            dispatchGroup.enter()
            UserService.shared.getUser(for: post.userID) { postAuthor in
                post.author = postAuthor
                let url = URL(string: post.author.profilePhotoURL)
                SDWebImageManager.shared.loadImage(with: url, progress: .none) { profilePhoto, _, _, _, _, _ in
                    post.author.profilePhoto = profilePhoto
                    print("loading profile photo")
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.enter()
            SDWebImageManager.shared.loadImage(with: URL(string: post.photoURL), progress: .none) { image, data, error, _, _, _ in
                if let downloadedImage = image {
                    post.image = downloadedImage
                }
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            LikeSystemService.shared.getLikesCountForPost(id: post.postID) { likesCount in
                post.likesCount = likesCount
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            CommentsService.shared.getCommentsCountForPost(postID: post.postID) { commentsCount in
                post.commentsCount = commentsCount
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            BookmarksService.shared.checkIfBookmarked(postID: post.postID) { bookmarkState in
                post.bookmarkState = bookmarkState
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            LikeSystemService.shared.checkIfPostIsLiked(postID: post.postID) { likeState in
                post.likeState = likeState
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(postsOfMultipleUsers)
        }
    }
    
    func getAdditionalPostDataFor(postsOfSingleUser: [UserPost], completion: @escaping ([UserPost]) -> Void) {
        guard postsOfSingleUser.isEmpty != true else {
            completion([UserPost]())
            return
        }
        print("inside get additiona post data method")
        let dispatchGroup = DispatchGroup()
        
        UserService.shared.getUser(for: postsOfSingleUser[0].userID) { postAuthor in
            print("got user data for single user")
            for post in postsOfSingleUser {
                post.author = postAuthor
                
                dispatchGroup.enter()
                SDWebImageManager.shared.loadImage(with: URL(string: post.photoURL), progress: .none) { image, data, error, _, _, _ in
                    if let downloadedImage = image {
                        post.image = downloadedImage
                    }
                    dispatchGroup.leave()
                }
                
                dispatchGroup.enter()
                let url = URL(string: post.author.profilePhotoURL)
                SDWebImageManager.shared.loadImage(with: url, progress: .none) { profilePhoto, _, _, _, _, _ in
                    post.author.profilePhoto = profilePhoto
                    dispatchGroup.leave()
                }
                
                dispatchGroup.enter()
                LikeSystemService.shared.getLikesCountForPost(id: post.postID) { likesCount in
                    post.likesCount = likesCount
                    print("likes count: \(likesCount)")
                    print("got likes count")
                    dispatchGroup.leave()
                }
                
                dispatchGroup.enter()
                CommentsService.shared.getCommentsCountForPost(postID: post.postID) { commentsCount in
                    post.commentsCount = commentsCount
                    print("got comments count")
                    dispatchGroup.leave()
                }
                
                dispatchGroup.enter()
                BookmarksService.shared.checkIfBookmarked(postID: post.postID) { bookmarkState in
                    post.bookmarkState = bookmarkState
                    dispatchGroup.leave()
                }
                
                dispatchGroup.enter()
                LikeSystemService.shared.checkIfPostIsLiked(postID: post.postID) { likeState in
                    post.likeState = likeState
                    dispatchGroup.leave()
                }
            }
            
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(postsOfSingleUser)
        }
    }
}
