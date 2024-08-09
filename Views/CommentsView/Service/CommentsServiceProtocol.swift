//
//  PostWithCommentsService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 17.05.2023.
//

import Foundation
import SDWebImage

protocol CommentsServiceProtocol: Sendable, PostActionsService {
    var userDataService: UserDataServiceProtocol { get }
    var postsService: UserPostsServiceProtocol { get }
    var commentsService: CommentSystemServiceProtocol { get }
    var likesService: LikeSystemServiceProtocol { get }
    var bookmarksService: BookmarksSystemServiceProtocol { get }

    func getComments() async throws -> [PostComment]
    func postComment(comment: PostComment) async throws
    func deleteComment(commentID: String) async throws
}

extension CommentsServiceProtocol {

    func getAdditionalPostData(for post: UserPost) async throws -> UserPost {
        var postWithAdditionalData = post
        let postID = post.postID

        async let profilePhoto = ImageService.shared.getImage(for: post.author.profilePhotoURL)
        async let likesCount = LikeSystemService.shared.getLikesCountForPost(id: postID)
        async let likeState = LikeSystemService.shared.checkIfPostIsLiked(postID: postID)
        async let bookmarkState = BookmarksSystemService.shared.checkIfBookmarked(postID: postID)
        try await postWithAdditionalData.likesCount = likesCount
        try await postWithAdditionalData.likeState = likeState
        try await postWithAdditionalData.bookmarkState = bookmarkState
        try await postWithAdditionalData.author.setProfilePhoto(profilePhoto)
        return postWithAdditionalData
    }
}

final class CommentsService: CommentsServiceProtocol {

    let postID: String
    let postAuthorID: String

    let userDataService: UserDataServiceProtocol
    let postsService: UserPostsServiceProtocol
    let commentsService: CommentSystemServiceProtocol
    let likesService: LikeSystemServiceProtocol
    let bookmarksService: BookmarksSystemServiceProtocol

    init(postID: String,
         postAuthorID: String,
         userDataService: UserDataServiceProtocol,
         postsService: UserPostsServiceProtocol,
         commentsService: CommentSystemServiceProtocol,
         likesService: LikeSystemServiceProtocol,
         bookmarksService: BookmarksSystemServiceProtocol) {
        self.postID = postID
        self.postAuthorID = postAuthorID
        self.userDataService = userDataService
        self.postsService = postsService
        self.commentsService = commentsService
        self.likesService = likesService
        self.bookmarksService = bookmarksService
    }

    func getCurrentUser() async -> ZoogramUser {
        return await UserManager.shared.getCurrentUser()
    }

    func getComments() async throws -> [PostComment] {
        var comments = try await commentsService.getCommentsForPost(postID: postID)
        do {
            try await withThrowingTaskGroup(of: (Int, PostComment).self) { group in
                for (index, comment) in comments.enumerated() {
                    group.addTask {
                        var commentWithPfp = comment
                        var commentAuthor = try await self.userDataService.getUser(for: comment.authorID)
                        let authorPfp = try await ImageService.shared.getImage(for: commentAuthor.profilePhotoURL)
                        commentAuthor.setProfilePhoto(authorPfp)
                        commentWithPfp.author = commentAuthor
                        return (index, commentWithPfp)
                    }
                }

                for try await (index, comment) in group {
                    comments[index] = comment
                }
            }
        } catch {
            throw ServiceError.couldntLoadComments
        }
        return comments
    }

    func postComment(comment: PostComment) async throws {
        let activityEvent = ActivityEvent.createActivityEventFor(comment: comment, postID: self.postID)
        async let commentWriteTask: Void = commentsService.postComment(for: postID, comment: comment)
        async let activityNotificationTask: Void = ActivitySystemService.shared.addEventToUserActivity(event: activityEvent, userID: self.postAuthorID)
        _ = try await [commentWriteTask, activityNotificationTask]
    }

    func deleteComment(commentID: String) async throws {
        async let commentDeletionTask: Void = commentsService.deleteComment(postID: postID, commentID: commentID)
        async let activityRemovalTask: Void = ActivitySystemService.shared.removeCommentEventForPost(commentID: commentID, postAuthorID: self.postAuthorID)
        _ = try await [commentDeletionTask, activityRemovalTask]
    }

    func likePost(postID: String, likeState: LikeState, postAuthorID: String) async throws {
        switch likeState {
        case .liked:
            async let likeRemovalTask: Void = likesService.removeLikeFromPost(postID: postID)
            async let activityRemovalTask: Void = ActivitySystemService.shared.removeLikeEventForPost(postID: postID, postAuthorID: postAuthorID)
            _ = try await [likeRemovalTask, activityRemovalTask]
        case .notLiked:
            let activityEvent = ActivityEvent.createActivityEventFor(likedPostID: postID)
            async let likeTask: Void = likesService.likePost(postID: postID)
            async let activityEventTask: Void = ActivitySystemService.shared.addEventToUserActivity(event: activityEvent, userID: postAuthorID)
            _ = try await [likeTask, activityEventTask]
        }
    }

    func deletePost(postModel: PostViewModel) async throws {
        try await postsService.deletePost(postID: postModel.postID, postImageURL: postModel.postImageURL)
    }

    func bookmarkPost(postID: String, authorID: String, bookmarkState: BookmarkState) async throws {
        switch bookmarkState {
        case .bookmarked:
            try await bookmarksService.removeBookmark(postID: postID)
        case .notBookmarked:
            try await bookmarksService.bookmarkPost(postID: postID, authorID: authorID)
        }
    }
}
