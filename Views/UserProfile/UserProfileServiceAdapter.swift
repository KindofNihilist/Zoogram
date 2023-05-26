//
//  UserProfileServiceAdapter.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.04.2023.
//

import Foundation

class UserProfileServiceAPIAdapter: UserProfileService, ImageService {

    var userID: String

    let followService: FollowSystemService
    let userPostsService: UserPostsService
    let userService: UserService
    let likeSystemService: LikeSystemService
    let bookmarksService: BookmarksService

    var dispatchGroup: DispatchGroup
    var lastReceivedPostKey: String = ""
    var isAlreadyPaginating: Bool = false
    var hasHitTheEndOfPosts: Bool = false

    init(userID: String, followService: FollowSystemService, userPostsService: UserPostsService, userService: UserService, likeSystemService: LikeSystemService, bookmarksService: BookmarksService) {
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
        userPostsService.getPostCount(for: userID) { postsCount in
            completion(postsCount)
        }
    }

    func getUserData(completion: @escaping (ZoogramUser) -> Void) {
        userService.getUser(for: userID) { user in
            let url = URL(string: user.profilePhotoURL)
            self.getImage(for: user.profilePhotoURL) { profilePhoto in
                user.profilePhoto = profilePhoto
                completion(user)
            }
        }
    }

    func getPosts(completion: @escaping ([PostViewModel]) -> Void) {
        userPostsService.getPosts(for: userID) { [weak self] posts, lastObtainedPostKey in
            self?.lastReceivedPostKey = lastObtainedPostKey
            print("got user profile posts")
            print(posts)
            self?.getAdditionalPostDataFor(postsOfSingleUser: posts) { postsWithAdditionalData in
                print("got additional data for profile posts")
                print("posts count: \(postsWithAdditionalData.count)")
                completion(postsWithAdditionalData.map { post in
                    PostViewModel(post: post)
                })
            }
        }
    }

    func getMorePosts(completion: @escaping ([PostViewModel]?) -> Void) {
        guard isAlreadyPaginating == false, lastReceivedPostKey != "" else {
            return
        }

        isAlreadyPaginating = true

        userPostsService.getMorePosts(after: lastReceivedPostKey, for: userID) { [weak self] posts, lastDownloadedPostKey in
            guard lastDownloadedPostKey != self?.lastReceivedPostKey else {
                self?.hasHitTheEndOfPosts = true
                print("Hit the end of user posts")
                return
            }
            print("got more posts for user")
            self?.lastReceivedPostKey = lastDownloadedPostKey
            self?.getAdditionalPostDataFor(postsOfSingleUser: posts) { postsWithAdditionalData in
                print("got additional post data for single user")
                self?.isAlreadyPaginating = false
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
            ActivitySystemService.shared.removeFollowEventForUser(userID: userID)
            completion(followStatus)
        }
    }

    func likePost(postID: String, likeState: LikeState, postAuthorID: String, completion: @escaping (LikeState) -> Void) {
        switch likeState {
        case .liked:
            likeSystemService.removePostLike(postID: postID) { result in
                switch result {
                case .success(let description):
                    ActivitySystemService.shared.removeLikeEventForPost(postID: postID, postAuthorID: postAuthorID)
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

                    let activityEvent = ActivityEvent.createActivityEventFor(likedPostID: postID)

                    ActivitySystemService.shared.addEventToUserActivity(event: activityEvent, userID: postAuthorID)
                    print(description)
                    completion(.liked)

                case .failure(let error):
                    print(error)
                    completion(.notLiked)
                }
            }
        }
    }

    func deletePost(postModel: PostViewModel, completion: @escaping () -> Void) {
        print("inside service adapter delete post method")
        userPostsService.deletePost(postID: postModel.postID, postImageURL: postModel.postImageURL) {
            completion()
        }
    }

    func bookmarkPost(postID: String, authorID: String, bookmarkState: BookmarkState, completion: @escaping (BookmarkState) -> Void) {

        switch bookmarkState {
        case .bookmarked:
            bookmarksService.removeBookmark(postID: postID) { bookmarkState in
                completion(bookmarkState)
                print("Successfully removed a bookmark")
            }
        case .notBookmarked:
            bookmarksService.bookmarkPost(postID: postID, authorID: authorID) { bookmarkState in
                completion(bookmarkState)
                print("Successfully bookmarked a post")
            }
        }

    }
}

func createUserProfileDefaultServiceFor(userID: String) -> UserProfileServiceAPIAdapter {
    UserProfileServiceAPIAdapter(userID: userID,
                                 followService: FollowSystemService.shared,
                                 userPostsService: UserPostsService.shared,
                                 userService: UserService.shared,
                                 likeSystemService: LikeSystemService.shared,
                                 bookmarksService: BookmarksService.shared)
}
