//
//  BookmarkedPostsServiceAdapter.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 12.04.2023.
//

import Foundation

class BookmarkedPostsServiceAdapter: PostsService {

    let bookmarksService: BookmarksService
    let likeSystemService: LikeSystemService
    let userPostsService: UserPostsService

    var listOfBookmarks = ListOfBookmarks()

    var lastReceivedPostKey: String = ""
    var isAlreadyPaginating: Bool = false
    var isPaginationAllowed: Bool = true
    var hasHitTheEndOfPosts: Bool = false

    init(bookmarksService: BookmarksService, likeSystemService: LikeSystemService, userPostsService: UserPostsService) {
        self.bookmarksService = bookmarksService
        self.likeSystemService = likeSystemService
        self.userPostsService = userPostsService
        self.bookmarksService.getListOfBookmarkedPosts { listOfBookmarks in
            self.listOfBookmarks = listOfBookmarks
        }
    }

    func getPosts(completion: @escaping ([PostViewModel]) -> Void) {
        bookmarksService.getBookmarkedPosts(numberOfPostsToGet: 21) { posts, lastRetrievedPostKey in
            print("got bookmarked posts")
            self.lastReceivedPostKey = lastRetrievedPostKey
            self.getAdditionalPostDataFor(postsOfMultipleUsers: posts) { postsWithAdditionalData in
                print("got additional data for bookmarked posts")
                completion(postsWithAdditionalData.map({ post in
                    PostViewModel(post: post)
                }))
            }
        }
    }

    func getMorePosts(completion: @escaping ([PostViewModel]?) -> Void) {
        bookmarksService.getMoreBookmarkedPosts(after: lastReceivedPostKey, numberOfPostsToGet: 21) { posts, lastRetrievedPostKey in
            self.lastReceivedPostKey = lastRetrievedPostKey
            self.getAdditionalPostDataFor(postsOfMultipleUsers: posts) { postsWithAdditionalData in
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
