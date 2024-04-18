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

    init(post: UserPost, commentIDToFocusOn: String?, shouldShowRelatedPost: Bool, currentUser: ZoogramUser, service: CommentsServiceProtocol) {
        self.service = service
        self.commentIDToFocusOn = commentIDToFocusOn
        self.shouldShowRelatedPost = shouldShowRelatedPost
        self.postViewModel = PostViewModel(post: post)
        self.relatedPost = post
        self.currentUser = currentUser
    }

    init(postViewModel: PostViewModel, commentIDToFocusOn: String?, shouldShowRelatedPost: Bool, currentUser: ZoogramUser, service: CommentsServiceProtocol) {
        self.service = service
        self.commentIDToFocusOn = commentIDToFocusOn
        self.shouldShowRelatedPost = shouldShowRelatedPost
        self.postViewModel = postViewModel
        self.currentUser = currentUser
        self.postCaption = createPostCaptionForCommentArea(with: postViewModel)
    }

    func fetchData(completion: @escaping (Error?) -> Void) {
        print("fetch data called")
        let dispatchGroup = DispatchGroup()

        if let post = self.relatedPost {
            dispatchGroup.enter()
            service.getAdditionalPostData(for: post) { result in
                switch result {
                case .success(let post):
                    self.postViewModel = PostViewModel(post: post)
                case .failure(let error):
                    completion(error)
                    return
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.enter()
        service.getComments { result in
            switch result {
            case .success(let comments):
                self.comments = comments.reversed().enumerated().map({ index, comment in
                    if comment.commentID == self.commentIDToFocusOn {
                        self.indexPathOfCommentToToFocusOn = IndexPath(row: index, section: 1)
                        self.hasAlreadyFocusedOnComment = false
                    }
                    comment.canBeEdited = self.checkIfCommentCanBeEdited(comment: comment)
                    return comment
                })
            case .failure(let error):
                completion(error)
                return
            }
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

    private func createPostComment(text: String) -> PostComment {
        let commentUID = CommentSystemService.shared.createCommentUID()
        let currentUserID = AuthenticationService.shared.getCurrentUserUID()!
        let formattedText = text.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        let postComent = PostComment(commentID: commentUID,
                                     authorID: currentUserID,
                                     commentText: formattedText,
                                     datePosted: Date())
        return postComent
    }

    func postComment(commentText: String, completion: @escaping (Result<PostComment, Error>) -> Void) {
        let newComment = createPostComment(text: commentText)

        service.postComment(comment: newComment) { result in
            switch result {
            case .success(let newlyCreatedComment):
                newlyCreatedComment.author = self.currentUser
                newlyCreatedComment.canBeEdited = true
                completion(.success(newlyCreatedComment))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func deleteComment(at indexPath: IndexPath, completion: @escaping (VoidResult) -> Void) {
        let comment = comments[indexPath.row]

        service.deleteComment(commentID: comment.commentID) { result in
            switch result {
            case .success:
                self.comments.remove(at: indexPath.row)
                completion(.success)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func deleteThisPost(completion: @escaping (VoidResult) -> Void) {
        let postViewModel = self.postViewModel
        service.deletePost(postModel: postViewModel) { result in
            completion(result)
        }
    }

    func likeThisPost(completion: @escaping (Result<LikeState, Error>) -> Void) {
        let postViewModel = self.postViewModel
        self.service.likePost(postID: postViewModel.postID,
                              likeState: postViewModel.likeState,
                              postAuthorID: postViewModel.author.userID) { result in
            switch result {
            case .success(let likeState):
                self.postViewModel.likeState = likeState
                completion(.success(likeState))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func bookmarkThisPost(completion: @escaping (Result<BookmarkState, Error>) -> Void) {
        let postViewModel = self.postViewModel
        self.service.bookmarkPost(postID: postViewModel.postID,
                                  authorID: postViewModel.author.userID,
                                  bookmarkState: postViewModel.bookmarkState) { result in
            switch result {
            case .success(let bookmarkState):
                self.postViewModel.bookmarkState = bookmarkState
                completion(.success(bookmarkState))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
