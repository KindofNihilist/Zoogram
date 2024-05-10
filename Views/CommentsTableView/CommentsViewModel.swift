//
//  PostWithCommentsViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 17.05.2023.
//

import Foundation
import UIKit

class CommentsViewModel {

    private let service: CommentsServiceProtocol

    private var currentUser: ZoogramUser
    var hasInitialzied = Observable(false)
    var shouldShowRelatedPost: Bool
    var shouldShowNewlyCreatedComment: Bool = false
    var hasAlreadyFocusedOnComment: Bool = true
    var isAlreadyScrolling: Bool = false
    var commentSectionIndex: Int = 0
    var indexPathOfCommentToToFocusOn: IndexPath?
    var postViewModel: PostViewModel
    var postCaption: PostComment?
    var comments = [PostComment]()
    private var commentIDToFocusOn: String?
    private var relatedPost: UserPost?

    init(post: UserPost, commentIDToFocusOn: String?, shouldShowRelatedPost: Bool, service: CommentsServiceProtocol) {
        self.currentUser = UserManager.shared.getCurrentUser()
        self.service = service
        self.commentIDToFocusOn = commentIDToFocusOn
        self.shouldShowRelatedPost = shouldShowRelatedPost
        self.postViewModel = PostViewModel(post: post)
        self.relatedPost = post
    }

    init(postViewModel: PostViewModel, commentIDToFocusOn: String?, shouldShowRelatedPost: Bool, service: CommentsServiceProtocol) {
        self.currentUser = UserManager.shared.getCurrentUser()
        self.service = service
        self.commentIDToFocusOn = commentIDToFocusOn
        self.shouldShowRelatedPost = shouldShowRelatedPost
        self.postViewModel = postViewModel
        self.postCaption = createPostCaptionForCommentArea(with: postViewModel)
    }

    func fetchData() async throws {
        if let post = self.relatedPost {
            let postWithAdditionalData = try await service.getAdditionalPostData(for: post)
            self.postViewModel = PostViewModel(post: postWithAdditionalData)
        }

        let comments = try await service.getComments()
        self.comments = comments.reversed().enumerated().map({ index, comment in
            if comment.commentID == self.commentIDToFocusOn {
                self.indexPathOfCommentToToFocusOn = IndexPath(row: index, section: 1)
                self.hasAlreadyFocusedOnComment = false
            }
            comment.canBeEdited = self.checkIfCommentCanBeEdited(comment: comment)
            return comment
        })

        self.hasInitialzied.value = true
    }

    func checkIfCommentCanBeEdited(comment: PostComment) -> Bool {
        if comment.authorID == currentUser.userID || postViewModel.author.userID == currentUser.userID {
            return true
        } else {
            return false
        }
    }

    func createPostCaptionForCommentArea(with postViewModel: PostViewModel?) -> PostComment? {
        guard let postViewModel = postViewModel, let caption = postViewModel.unAttributedPostCaption else {
            return nil
        }
        let postCaption = PostComment(
            commentID: "",
            authorID: postViewModel.author.userID,
            commentText: caption,
            datePosted: postViewModel.datePosted,
            author: postViewModel.author)

        return postCaption
    }

    func getCurrentUserProfilePicture() -> UIImage? {
        return currentUser.getProfilePhoto()
    }

    private func getPostCaption() -> PostComment? {
        if shouldShowRelatedPost {
            return nil
        } else {
            let postCaption = createPostCaptionForCommentArea(with: self.postViewModel)
            return postCaption
        }
    }

    func getPostViewModel() -> PostViewModel {
        return self.postViewModel
    }

    func insertNewlyCreatedComment(comment: PostComment) {
        comment.shouldBeMarkedUnseen = true
        self.comments.insert(comment, at: 0)
        self.shouldShowNewlyCreatedComment = true
        self.indexPathOfCommentToToFocusOn = IndexPath(row: 0, section: commentSectionIndex)
    }

    func getComments() -> [PostComment] {
        return self.comments
    }

    func getComment(for indexPath: IndexPath) -> PostComment {
        return comments[indexPath.row]
    }

    func getLatestComment() -> PostComment? {
        return comments.first
    }

    private func createPostComment(text: String) throws -> PostComment {
        let commentUID = CommentSystemService.shared.createCommentUID()
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let formattedText = text.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        let postComent = PostComment(commentID: commentUID,
                                     authorID: currentUserID,
                                     commentText: formattedText,
                                     datePosted: Date())
        return postComent
    }

    func postComment(commentText: String) async throws -> PostComment {
        let newComment = try createPostComment(text: commentText)

        let postedComment = try await service.postComment(comment: newComment)
        postedComment.author = currentUser
        postedComment.canBeEdited = true
        return postedComment
    }

    func deleteComment(at indexPath: IndexPath) async throws {
        let comment = comments[indexPath.row]

        try await service.deleteComment(commentID: comment.commentID)
        self.comments.remove(at: indexPath.row)
    }

    func deleteThisPost() async throws {
        let postViewModel = self.postViewModel
        try await service.deletePost(postModel: postViewModel)
    }

    func likeThisPost() async throws -> LikeState {
        let postViewModel = self.postViewModel
        let likeState = try await service.likePost(postID: postViewModel.postID, likeState: postViewModel.likeState, postAuthorID: postViewModel.author.userID)
        postViewModel.likeState = likeState
        return likeState
    }

    func bookmarkThisPost() async throws -> BookmarkState {
        let postViewModel = self.postViewModel
        let bookmarkState = try await service.bookmarkPost(postID: postViewModel.postID,
                                                           authorID: postViewModel.author.userID,
                                                           bookmarkState: postViewModel.bookmarkState)
        postViewModel.bookmarkState = bookmarkState
        return bookmarkState
    }
}
