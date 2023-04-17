//
//  UserProfileServiceAdapter.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.04.2023.
//

import Foundation

class UserProfileServiceAPIAdapter: UserProfileService {
    
    var userID: String
    
    let followService: FollowService
    let userPostsService: UserPostsService
    let userService: UserService
    let likeSystemService: LikeSystemService
    let bookmarksService: BookmarksService
    
    var dispatchGroup: DispatchGroup
    var lastReceivedPostKey: String = ""
    var isAlreadyPaginating: Bool = false
    var hasHitTheEndOfPosts: Bool = false
    
    init(userID: String, followService: FollowService, userPostsService: UserPostsService, userService: UserService, likeSystemService: LikeSystemService, bookmarksService: BookmarksService) {
        self.userID = userID
        self.followService = followService
        self.userPostsService = userPostsService
        self.userService = userService
        self.likeSystemService = likeSystemService
        self.bookmarksService = bookmarksService
        self.dispatchGroup = DispatchGroup()
    }
    
    func getFollowersCount(completion: @escaping (Int) -> Void) {
        followService.getFollowersNumber(for: userID) { followersCount in
            completion(followersCount)
        }
    }
    
    func getFollowingCount(completion: @escaping (Int) -> Void) {
        followService.getFollowingNumber(for: userID) { followingCount in
            completion(followingCount)
        }
    }
    
    func getPostsCount(completion: @escaping (Int) -> Void) {
        userPostsService.observePostCount(for: userID) { postsCount in
            completion(postsCount)
        }
    }
    
    func getUserData(completion: @escaping (ZoogramUser) -> Void) {
        userService.observeUser(for: userID) { user in
            let url = URL(string: user.profilePhotoURL)
            user.profilePhoto  = getImageForURL(url!)
            completion(user)
        }
    }
    
   
    
    func getPosts(completion: @escaping ([PostViewModel]) -> Void) {
        userPostsService.getPosts(for: userID) { [weak self] posts, lastObtainedPostKey in
            self?.lastReceivedPostKey = lastObtainedPostKey
            print("got user profile posts")
            print(posts)
            self?.getAdditionalPostDataFor(postsOfMultipleUsers: posts) { postsWithAdditionalData in
                print("got additional data for profile posts")
                print("posts count: \(postsWithAdditionalData.count)")
                completion(postsWithAdditionalData.map { post in
                    PostViewModel(post: post)
                })
            }
        }
    }
    
    func getMorePosts(completion: @escaping ([PostViewModel]) -> Void) {
        guard lastReceivedPostKey != "" else {
            return
        }
        
        isAlreadyPaginating = true
        
        userPostsService.getMorePosts(after: lastReceivedPostKey, for: userID) { [weak self] posts, lastDownloadedPostKey in
            guard lastDownloadedPostKey != self?.lastReceivedPostKey else {
                self?.hasHitTheEndOfPosts = true
                print("Hit the end of user posts")
                return
            }
            self?.lastReceivedPostKey = lastDownloadedPostKey
            self?.isAlreadyPaginating = false
            self?.getAdditionalPostDataFor(postsOfSingleUser: posts) { postsWithAdditionalData in
                completion(postsWithAdditionalData.map({ post in
                    PostViewModel(post: post)
                }))
            }
        }
    }
    
    func followUser(completion: @escaping (FollowStatus) -> Void) {
        followService.followUser(uid: userID) { followStatus in
            completion(followStatus)
        }
    }
    
    func unfollowUser(completion: @escaping (FollowStatus) -> Void) {
        followService.unfollowUser(uid: userID) { [userID] followStatus in
            ActivityService.shared.removeFollowEventForUser(userID: userID)
            completion(followStatus)
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
        userPostsService.deletePost(post: post) {
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
