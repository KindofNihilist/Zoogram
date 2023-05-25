//
//  PostWithCommentsViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 17.05.2023.
//

import Foundation
import UIKit

class PostWithCommentsViewModel {

    private let service: PostWithCommentsService

    private var currentUser: ZoogramUser

    var hasInitialzied = Observable(false)

//    var shouldShowRelatedPost: Bool = false

    var hasAlreadyFocusedOnComment: Bool = false

    var indexPathOfCommentToToFocusOn: IndexPath?

    var commentSection: Int

    private var commentIDToFocusOn: String?

    private var postViewModel: PostViewModel?

    private var postCaption: String?

    private var comments = [CommentViewModel]()

    init(post: UserPost?, caption: String?, commentIDToFocusOn: String?, service: PostWithCommentsService) {
        self.service = service
        self.postCaption = caption
        self.commentIDToFocusOn = commentIDToFocusOn
        self.currentUser = UserService.shared.currentUser
        if let post = post {
            self.postViewModel = PostViewModel(post: post)
//            self.shouldShowRelatedPost = true
        }
        fetchDataOnInit(post: post)
    }

    func getCommentSection() -> Int {
        if postViewModel != nil || postCaption != nil {
            return 1
        } else {
            return 0
        }
    }

    private func fetchDataOnInit(post: UserPost?) {
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
                return CommentViewModel(comment: comment)
            })
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            self.hasInitialzied.value = true
        }
    }

    func getNumberOfRowsIn(section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return comments.count
        }
    }

    func getPostCaption() -> CommentViewModel? {
        let postCaption = CommentViewModel.createPostCaptionForCommentArea(with: self.postViewModel)
        return postCaption
    }

    func getPostViewModel() -> PostViewModel? {
        return self.postViewModel
    }

    func getComments() -> [CommentViewModel] {
        return self.comments
    }

//    func getTableViewCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
//        let hasPost = postViewModel == nil ? false : true
//        let hasCaption = postCaption == nil ? false : true
//
//        if indexPath.section == 0 && hasPost {
//            let cell = createPostCell(for: tableView, at: indexPath)
//            return cell
//        } else if indexPath.section == 0 && hasCaption {
//            let cell = createCaptionCell(for: tableView, at: indexPath)
//            return cell
//        } else {
//            let cell = createCommentCell(for: tableView, at: indexPath)
//            return cell
//        }
//    }
//
//    private func createCaptionCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
//        guard let postCaption = postCaption else {
//            return UITableViewCell()
//        }
//
//        let cell: CommentTableViewCell = tableView.dequeue(withIdentifier: CommentTableViewCell.identifier, for: indexPath)
//        let comment = PostComment
//
//    }
//
//    private func createCommentCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
//        let cell: CommentTableViewCell = tableView.dequeue(withIdentifier: CommentTableViewCell.identifier, for: indexPath)
//    }
//
//    private func createPostCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
//        let cell: PostTableViewCell = tableView.dequeue(withIdentifier: PostTableViewCell.identifier, for: indexPath)
//    }

    func getComment(for indexPath: IndexPath) -> CommentViewModel {
        return comments[indexPath.row]
    }

    func postComment(commentText: String, completion: @escaping () -> Void) {

        let newComment = PostComment.createPostComment(text: commentText)
        
        service.postComment(comment: newComment) { newlyCreatedComment in
            newlyCreatedComment.author = self.currentUser
            let commentViewModel = CommentViewModel(comment: newlyCreatedComment)
            self.comments.append(commentViewModel)
            completion()
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
        guard let postViewModel = self.postViewModel else {
            return
        }
        service.deletePost(postModel: postViewModel) {
            completion()
        }
    }

    func likeThisPost(completion: @escaping (LikeState) -> Void) {
        guard let postViewModel = self.postViewModel else {
            return
        }
        self.service.likePost(postID: postViewModel.postID,
                              likeState: postViewModel.likeState,
                              postAuthorID: postViewModel.author.userID) { likeState in
            self.postViewModel!.likeState = likeState
            completion(likeState)
        }
    }

    func bookmarkThisPost(completion: @escaping (BookmarkState) -> Void) {
        guard let postViewModel = self.postViewModel else {
            return
        }
        self.service.bookmarkPost(postID: postViewModel.postID,
                                  authorID: postViewModel.author.userID,
                                  bookmarkState: postViewModel.bookmarkState) { bookmarkState in
            self.postViewModel!.bookmarkState = bookmarkState
            completion(bookmarkState)
        }
    }
}
