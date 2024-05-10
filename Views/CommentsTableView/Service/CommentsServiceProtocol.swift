//
//  PostWithCommentsService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 17.05.2023.
//

import Foundation
import SDWebImage

protocol CommentsServiceProtocol: ImageService, PostActionsService {
    var userDataService: UserDataServiceProtocol { get }
    var postsService: UserPostsServiceProtocol { get }
    var commentsService: CommentSystemServiceProtocol { get }
    var likesService: LikeSystemServiceProtocol { get }
    var bookmarksService: BookmarksSystemServiceProtocol { get }

    var postID: String { get set }
    var postAuthorID: String { get set }
    func getComments() async throws -> [PostComment]
    func postComment(comment: PostComment) async throws -> PostComment
    func deleteComment(commentID: String) async throws
}

extension CommentsServiceProtocol {

    func getAdditionalPostData(for post: UserPost) async throws -> UserPost {

        if let profilePhotoURL = post.author.profilePhotoURL {
            let profilePhoto = try await getImage(for: profilePhotoURL)
            post.author.setProfilePhoto(profilePhoto)
        }

        let postID = post.postID
        post.likesCount = try await LikeSystemService.shared.getLikesCountForPost(id: postID)
        post.likeState = try await LikeSystemService.shared.checkIfPostIsLiked(postID: postID)
        post.bookmarkState = try await BookmarksSystemService.shared.checkIfBookmarked(postID: postID)
        return post
    }
}

class CommentsService: ImageService, CommentsServiceProtocol {

    var postID: String

    var postAuthorID: String

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
         bookmarksService: BookmarksSystemServiceProtocol)
    {
        self.postID = postID
        self.postAuthorID = postAuthorID
        self.userDataService = userDataService
        self.postsService = postsService
        self.commentsService = commentsService
        self.likesService = likesService
        self.bookmarksService = bookmarksService
    }

    func getCurrentUser() -> ZoogramUser {
        return UserManager.shared.getCurrentUser()
    }

    func getComments() async throws -> [PostComment] {
        let comments = try await commentsService.getCommentsForPost(postID: postID)
        for comment in comments {
            let authorPfp = try await getImage(for: comment.author.profilePhotoURL)
            comment.author.setProfilePhoto(authorPfp)
        }
        return comments
    }

    func postComment(comment: PostComment) async throws -> PostComment {
        try await commentsService.postComment(for: postID, comment: comment)
        let activityEvent = ActivityEvent.createActivityEventFor(comment: comment, postID: self.postID)
        try await ActivitySystemService.shared.addEventToUserActivity(event: activityEvent, userID: self.postAuthorID)
        comment.author = try await userDataService.getUser(for: comment.authorID)
        return comment
    }

    func deleteComment(commentID: String) async throws {
        try await commentsService.deleteComment(postID: postID, commentID: commentID)
        try await ActivitySystemService.shared.removeCommentEventForPost(commentID: commentID, postAuthorID: self.postAuthorID)
    }

    func likePost(postID: String, likeState: LikeState, postAuthorID: String) async throws -> LikeState {
        switch likeState {
        case .liked:
            try await likesService.removeLikeFromPost(postID: postID)
            try await ActivitySystemService.shared.removeLikeEventForPost(postID: postID, postAuthorID: postAuthorID)
            return .notLiked
        case .notLiked:
            try await likesService.likePost(postID: postID)
            let activityEvent = ActivityEvent.createActivityEventFor(likedPostID: postID)
            try await ActivitySystemService.shared.addEventToUserActivity(event: activityEvent, userID: postAuthorID)
            return .liked
        }
    }

    func deletePost(postModel: PostViewModel) async throws {
        try await postsService.deletePost(postID: postModel.postID, postImageURL: postModel.postImageURL)
    }

    func bookmarkPost(postID: String, authorID: String, bookmarkState: BookmarkState) async throws -> BookmarkState {
        switch bookmarkState {
        case .bookmarked:
            return try await bookmarksService.removeBookmark(postID: postID)
        case .notBookmarked:
            return try await bookmarksService.bookmarkPost(postID: postID, authorID: authorID)
        }
    }
}
