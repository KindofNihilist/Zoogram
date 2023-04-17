//
//  Adapters.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 07.04.2023.
//

import Foundation

class HomeFeedPostsAPIServiceAdapter: PostsService {
    
    let homeFeedService: HomeFeedService
    let likeSystemService: LikeSystemService
    let userPostService: UserPostsService
    let bookmarksService: BookmarksService
    
    var lastReceivedPostKey: String = ""
    var isAlreadyPaginating: Bool = false
    var hasHitTheEndOfPosts: Bool = false
    
    init(homeFeedService: HomeFeedService, likeSystemService: LikeSystemService, userPostService: UserPostsService, bookmarksService: BookmarksService) {
        
        self.homeFeedService = homeFeedService
        self.likeSystemService = likeSystemService
        self.userPostService = userPostService
        self.bookmarksService = bookmarksService
    }
    
    func getPosts(completion: @escaping ([PostViewModel]) -> Void) {
        homeFeedService.getPostsForTimeline { [weak self] posts, lastPostKey in
            guard posts.isEmpty != true else {
                completion([PostViewModel]())
                return
            }
            print("Downloaded posts, last post key: \(lastPostKey)")
            self?.lastReceivedPostKey = lastPostKey
            self?.getAdditionalPostDataFor(postsOfMultipleUsers: posts) { postsWithAditionalData in
                print("Got additional posts data")
                completion(postsWithAditionalData.map({ post in
                    PostViewModel(post: post)
                }))
            }
        }
    }
    
    func getMorePosts(completion: @escaping ([PostViewModel]) -> Void) {
        guard isAlreadyPaginating == false, lastReceivedPostKey != "" else {
            return
        }
        
        isAlreadyPaginating = true
        
        homeFeedService.getMorePostsForTimeline(after: lastReceivedPostKey) { [weak self] posts, lastPostKey in
            guard posts.isEmpty != true, lastPostKey != self?.lastReceivedPostKey else {
                print("Hit the end of user posts")
                self?.hasHitTheEndOfPosts = true
                completion([PostViewModel]())
                return
            }
            print("Downloaded feed posts with last post key: \(lastPostKey)")
            self?.lastReceivedPostKey = lastPostKey
            self?.getAdditionalPostDataFor(postsOfMultipleUsers: posts) { postsWithAdditionalData in
                self?.isAlreadyPaginating = false
                completion(postsWithAdditionalData.map({ post in
                    PostViewModel(post: post)
                }))
            } 
        }
    }
    
    func likePost(postID: String, likeState: LikeState, postAuthorID: String, completion: @escaping (LikeState) -> Void) {
        switch likeState {
        case .liked:
            likeSystemService.removePostLike(postID: postID) { result in
                switch result {
                case .success(let description):
                    ActivityService.shared.removeLikeEventForPost(postID: postID, postAuthorID: postAuthorID)
                    print(description)
                    completion(.notLiked)
                case .failure(let error):
                    print(error)
                    completion(.liked)
                }
            }
        case .notLiked:
            likeSystemService.likePost(postID: postID) { result in
                switch result {
                case .success(let description):
                    let currentUserID = AuthenticationManager.shared.getCurrentUserUID()
                    let eventID = ActivityService.shared.createEventUID()
                    let activityEvent = ActivityEvent(eventType: .postLiked, userID: currentUserID, postID: postID, eventID: eventID, date: Date())
                    ActivityService.shared.addEventToUserActivity(event: activityEvent, userID: postAuthorID)
                    print(description)
                    completion(.liked)
                case .failure(let error):
                    print(error)
                    completion(.notLiked)
                }
            }
        }
    }
    
    func deletePost(post: PostViewModel, at indexPath: IndexPath, completion: @escaping () -> Void) {
        userPostService.deletePost(post: post) {
            NotificationCenter.default.post(name: Notification.Name("PostDeleted"), object: indexPath.row)
            completion()
        }
    }
    
    func bookmarkPost(postID: String, authorID: String) {
        bookmarksService.bookmarkPost(postID: postID, authorID: authorID) {
            print("Successfully bookmarked a post")
        }
    }
    
    func removeBookmark(postID: String) {
        bookmarksService.removeBookmark(postID: postID) {
            print("Successfully removed bookmark")
        }
    }
}


class UserPostsAPIServiceAdapter: PostsService {
    var lastReceivedPostKey: String = ""
    
    var isAlreadyPaginating: Bool = false
    var hasHitTheEndOfPosts: Bool = false
    
    func likePost(postID: String, likeState: LikeState, postAuthorID: String, completion: @escaping (LikeState) -> Void) {
        
    }
    
    func deletePost(post: PostViewModel, at indexPath: IndexPath, completion: @escaping () -> Void) {
        
    }
    
    func bookmarkPost(postID: String, authorID: String) {
        
    }
    
    func removeBookmark(postID: String) {
        
    }
    
    func getPosts(completion: @escaping ([PostViewModel]) -> Void) {
        
    }
    
    func getMorePosts(completion: @escaping ([PostViewModel]) -> Void) {
        
    }
}
