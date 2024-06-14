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
    func postComment(comment: PostComment) async throws -> PostComment
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
        try await withThrowingTaskGroup(of: (Int, PostComment).self) { group in

            for (index, comment) in comments.enumerated() {
                group.addTask {
                    var commentWithPfp = comment
                    let authorPfp = try await ImageService.shared.getImage(for: comment.author.profilePhotoURL)
                    commentWithPfp.author.setProfilePhoto(authorPfp)
                    return (index, commentWithPfp)
                }
            }

            for try await (index, comment) in group {
                comments[index] = comment
            }
        }
        return comments
    }

    func postComment(comment: PostComment) async throws -> PostComment {
        var commentToPost = comment
        try await commentsService.postComment(for: postID, comment: commentToPost)
        let activityEvent = ActivityEvent.createActivityEventFor(comment: commentToPost, postID: self.postID)
        try await ActivitySystemService.shared.addEventToUserActivity(event: activityEvent, userID: self.postAuthorID)
        commentToPost.author = try await userDataService.getUser(for: commentToPost.authorID)
        return commentToPost
    }

    func deleteComment(commentID: String) async throws {
        try await commentsService.deleteComment(postID: postID, commentID: commentID)
        try await ActivitySystemService.shared.removeCommentEventForPost(commentID: commentID, postAuthorID: self.postAuthorID)
    }

    func likePost(postID: String, likeState: LikeState, postAuthorID: String) async throws {
        switch likeState {
        case .liked:
            try await likesService.removeLikeFromPost(postID: postID)
            try await ActivitySystemService.shared.removeLikeEventForPost(postID: postID, postAuthorID: postAuthorID)
        case .notLiked:
            try await likesService.likePost(postID: postID)
            let activityEvent = ActivityEvent.createActivityEventFor(likedPostID: postID)
            try await ActivitySystemService.shared.addEventToUserActivity(event: activityEvent, userID: postAuthorID)
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
