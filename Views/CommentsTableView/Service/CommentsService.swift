//
//  PostWithCommentsService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 17.05.2023.
//

import Foundation
import SDWebImage

protocol CommentsService: PostActionsService, ImageService {
    var postID: String { get set }
    var postAuthorID: String { get set }
    func getComments(completion: @escaping ([PostComment]) -> Void)
    func postComment(comment: PostComment, completion: @escaping (PostComment) -> Void)
    func deleteComment(commentID: String, completion: @escaping () -> Void)
}

extension CommentsService {

    func getAdditionalPostData(for post: UserPost, completion: @escaping (UserPost) -> Void) {

        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        getImage(for: post.author.profilePhotoURL) { profilePhoto in
            post.author.profilePhoto = profilePhoto
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        LikeSystemService.shared.getLikesCountForPost(id: post.postID) { likesCount in
            post.likesCount = likesCount
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

        dispatchGroup.notify(queue: .main) {
            completion(post)
        }
    }
}

class PostWithCommentsServiceAdapter: CommentsService {

    var postID: String

    var postAuthorID: String

    let postsService: UserPostsService
    let commentsService: CommentSystemService
    let likesService: LikeSystemService
    let bookmarksService: BookmarksService

    init(postID: String, postAuthorID: String, postsService: UserPostsService, commentsService: CommentSystemService, likesService: LikeSystemService, bookmarksService: BookmarksService) {
        self.postID = postID
        self.postAuthorID = postAuthorID
        self.postsService = postsService
        self.commentsService = commentsService
        self.likesService = likesService
        self.bookmarksService = bookmarksService
    }

    func getComments(completion: @escaping ([PostComment]) -> Void) {
        commentsService.getCommentsForPost(postID: postID) { comments in
            let dispatchGroup = DispatchGroup()

            for comment in comments {
                print(comment.commentText)
                dispatchGroup.enter()
                self.getImage(for: comment.author.profilePhotoURL) { image in
                    comment.author.profilePhoto = image
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.notify(queue: .main) {
                completion(comments)
            }
        }
    }

    func postComment(comment: PostComment, completion: @escaping (PostComment) -> Void) {
        CommentSystemService.shared.postComment(for: postID, comment: comment) {

            // Adding activity event to user activity timeline
            let activityEvent = ActivityEvent.createActivityEventFor(comment: comment, postID: self.postID)

            ActivitySystemService.shared.addEventToUserActivity(event: activityEvent, userID: self.postAuthorID)

            // Receiveing newly made comment's author profile to append it to tableView
            UserService.shared.getUser(for: comment.authorID) { author in
                comment.author = author
                completion(comment)
            }
        }
    }

    func deleteComment(commentID: String, completion: @escaping () -> Void) {
        commentsService.deleteComment(postID: postID, commentID: commentID) {
            ActivitySystemService.shared.removeCommentEventForPost(commentID: commentID, postAuthorID: self.postAuthorID)
            completion()
        }
    }

    func likePost(postID: String, likeState: LikeState, postAuthorID: String, completion: @escaping (LikeState) -> Void) {

        switch likeState {
        case .liked:
            likesService.removePostLike(postID: postID) { result in
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
            likesService.likePost(postID: postID) { result in
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
        postsService.deletePost(postID: postModel.postID, postImageURL: postModel.postImageURL) {
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
