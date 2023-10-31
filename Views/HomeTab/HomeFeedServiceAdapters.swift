//
//  HomeFeedServiceAdapters.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 09.05.2023.
//

import Foundation

class HomeFeedPostsAPIServiceAdapter: HomeFeedService {

    let feedService: FeedService
    let likeSystemService: LikeSystemService
    let userPostService: UserPostsService
    let bookmarksService: BookmarksService
    let storageManager: StorageManager

    var lastReceivedPostKey: String = ""
    var isAlreadyPaginating: Bool = false
    var isPaginationAllowed: Bool = true
    var hasHitTheEndOfPosts: Bool = false

    init(feedService: FeedService, likeSystemService: LikeSystemService, userPostService: UserPostsService, bookmarksService: BookmarksService, storageManager: StorageManager) {

        self.feedService = feedService
        self.likeSystemService = likeSystemService
        self.userPostService = userPostService
        self.bookmarksService = bookmarksService
        self.storageManager = storageManager
    }

    func makeANewPost(post: UserPost, progressUpdateCallback: @escaping (Progress?) -> Void, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let image = post.image else {
            return
        }
        let fileName = "\(post.postID)_post.png"

        storageManager.uploadPostPhoto(photo: image, fileName: fileName) { progress in
            progressUpdateCallback(progress)
        } completion: { result in
            switch result {

            case .success(let photoURL):

                post.photoURL = photoURL.absoluteString

                self.userPostService.insertNewPost(post: post) { result in
                    completion(result)
                }
            case .failure(let error):
                completion(Result.failure(error))
            }
        }
    }

    func getPosts(completion: @escaping ([PostViewModel]) -> Void) {
        feedService.getPostsForTimeline { [weak self] posts, lastPostKey in
            guard posts.isEmpty != true else {
                completion([PostViewModel]())
                return
            }
//            print("Downloaded posts, last post key: \(lastPostKey)")
            self?.lastReceivedPostKey = lastPostKey
            self?.hasHitTheEndOfPosts = false
            self?.getAdditionalPostDataFor(postsOfMultipleUsers: posts) { postsWithAditionalData in
                completion(postsWithAditionalData.map({ post in
                    PostViewModel(post: post)
                }))
            }
        }
    }

    func getMorePosts(completion: @escaping ([PostViewModel]?) -> Void) {
        guard isAlreadyPaginating == false, lastReceivedPostKey != "" else {
            completion(nil)
            return
        }

        isAlreadyPaginating = true

        feedService.getMorePostsForTimeline(after: lastReceivedPostKey) { [weak self] posts, lastPostKey in
            guard posts.isEmpty != true, lastPostKey != self?.lastReceivedPostKey else {
                self?.isAlreadyPaginating = false
                self?.hasHitTheEndOfPosts = true
                completion(nil)
                print("Hit the end of user posts")
                return
            }
//            print("Downloaded feed posts with last post key: \(lastPostKey)")
            self?.lastReceivedPostKey = lastPostKey
            self?.getAdditionalPostDataFor(postsOfMultipleUsers: posts) { postsWithAdditionalData in
                let postsViewModels = postsWithAdditionalData.map { post in
                    PostViewModel(post: post)
                }
                completion(postsViewModels)
            }
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
                    let currentUserID = AuthenticationManager.shared.getCurrentUserUID()
                    let eventID = ActivitySystemService.shared.createEventUID()
                    let activityEvent = ActivityEvent(eventType: .postLiked, userID: currentUserID, postID: postID, eventID: eventID, date: Date())
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
        userPostService.deletePost(postID: postModel.postID, postImageURL: postModel.postImageURL) {
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
