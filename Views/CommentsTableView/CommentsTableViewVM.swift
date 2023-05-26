//
//  PostWithCommentsViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 17.05.2023.
//

import Foundation
import UIKit

class CommentsTableViewVM {

    private let service: CommentsService

    private var currentUser: ZoogramUser

    var hasInitialzied = Observable(false)

    var shouldShowRelatedPost: Bool

    var shouldShowNewlyCreatedComment: Bool = false

    var hasAlreadyFocusedOnComment: Bool = false

    var indexPathOfCommentToToFocusOn: IndexPath?

    private var commentIDToFocusOn: String?

    private var postViewModel: PostViewModel

    private var comments = [CommentViewModel]()

    init(post: UserPost, commentIDToFocusOn: String?, shouldShowRelatedPost: Bool, service: CommentsService) {
        self.service = service
        self.commentIDToFocusOn = commentIDToFocusOn
        self.currentUser = UserService.shared.currentUser
        self.shouldShowRelatedPost = shouldShowRelatedPost
        self.postViewModel = PostViewModel(post: post)
        fetchDataOnInit(post: post)
    }

    init(postViewModel: PostViewModel, commentIDToFocusOn: String?, shouldShowRelatedPost: Bool, service: CommentsService) {
        self.service = service
        self.commentIDToFocusOn = commentIDToFocusOn
        self.currentUser = UserService.shared.currentUser
        self.shouldShowRelatedPost = shouldShowRelatedPost
        self.postViewModel = postViewModel
        fetchDataOnInit()
    }

    private func fetchDataOnInit(post: UserPost? = nil) {
        let dispatchGroup = DispatchGroup()

        if let post = post {
            dispatchGroup.enter()
            service.getAdditionalPostData(for: post) { post in
                self.postViewModel = PostViewModel(post: post)
                dispatchGroup.leave()
            }
        }

        dispatchGroup.enter()
        service.getComments { comments in
            self.comments = comments.enumerated().map({ index, comment in
                if comment.commentID == self.commentIDToFocusOn {
                    self.indexPathOfCommentToToFocusOn = IndexPath(row: index, section: 1)
                }
                let canBeEdited = self.checkIfCommentCanBeEdited(comment: comment)
                return CommentViewModel(comment: comment, canBeEdited: canBeEdited)
            })
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            self.hasInitialzied.value = true
        }
    }

    func checkIfCommentCanBeEdited(comment: PostComment) -> Bool {
        if comment.authorID == currentUser.userID || postViewModel.author.userID == currentUser.userID {
            return true
        } else {
            return false
        }
    }

    func getCurrentUserProfilePicture() -> UIImage? {
        return currentUser.profilePhoto
    }

    func getPostCaption() -> CommentViewModel? {
        if shouldShowRelatedPost {
            return nil
        } else {
            let postCaption = CommentViewModel.createPostCaptionForCommentArea(with: self.postViewModel)
            return postCaption
        }
    }

    func getPostViewModel() -> PostViewModel {
        return self.postViewModel
    }

    func insertNewlyCreatedComment(comment: CommentViewModel) {
        self.comments.insert(comment, at: 0)
        self.shouldShowNewlyCreatedComment = true
    }

    func getComments() -> [CommentViewModel] {
        return self.comments
    }

    func getComment(for indexPath: IndexPath) -> CommentViewModel {
        return comments[indexPath.row]
    }

    func postComment(commentText: String, completion: @escaping (CommentViewModel) -> Void) {

        let newComment = PostComment.createPostComment(text: commentText)

        service.postComment(comment: newComment) { newlyCreatedComment in
            newlyCreatedComment.author = self.currentUser
            let commentViewModel = CommentViewModel(comment: newlyCreatedComment, canBeEdited: true)
            self.comments.append(commentViewModel)
            completion(commentViewModel)
        }
    }

    func deleteComment(at indexPath: IndexPath, completion: @escaping () -> Void) {
        let comment = comments[indexPath.row]

        service.deleteComment(commentID: comment.commentID) {
            self.comments.remove(at: indexPath.row)
            completion()
        }
    }

    func deleteThisPost(completion: @escaping () -> Void) {
        let postViewModel = self.postViewModel
        service.deletePost(postModel: postViewModel) {
            completion()
        }
    }

    func likeThisPost(completion: @escaping (LikeState) -> Void) {
        let postViewModel = self.postViewModel
        self.service.likePost(postID: postViewModel.postID,
                              likeState: postViewModel.likeState,
                              postAuthorID: postViewModel.author.userID) { likeState in
            self.postViewModel.likeState = likeState
            completion(likeState)
        }
    }

    func bookmarkThisPost(completion: @escaping (BookmarkState) -> Void) {
        let postViewModel = self.postViewModel
        self.service.bookmarkPost(postID: postViewModel.postID,
                                  authorID: postViewModel.author.userID,
                                  bookmarkState: postViewModel.bookmarkState) { bookmarkState in
            self.postViewModel.bookmarkState = bookmarkState
            completion(bookmarkState)
        }
    }
}
