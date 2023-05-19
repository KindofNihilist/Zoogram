//
//  CommentsViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 01.02.2023.
//

import Foundation

class CommentsViewModel {

    var postComments = [CommentViewModel]()

    func postComment(postID: String, postAuthorID: String, comment: String, completion: @escaping () -> Void) {
        guard !comment.isEmpty else {
            return
        }

        let postComment = PostComment.createPostComment(text: comment)

        CommentSystemService.shared.postComment(for: postID, comment: postComment) {

            // Adding activity event to user activity timeline
            let eventID = ActivitySystemService.shared.createEventUID()
            let activityEvent = ActivityEvent(eventType: .postCommented,
                                              userID: postComment.authorID,
                                              postID: postID,
                                              eventID: eventID,
                                              date: Date(),
                                              text: postComment.commentText,
                                              commentID: postComment.commentID)
            ActivitySystemService.shared.addEventToUserActivity(event: activityEvent, userID: postAuthorID)

            // Receiveing newly made comment's author profile to append it to tableView
            UserService.shared.getUser(for: postComment.authorID) { author in
                postComment.author = author
                self.postComments.append(CommentViewModel(comment: postComment))
                completion()
            }
        }
    }

    func getComments(for postID: String, completion: @escaping () -> Void) {
        CommentSystemService.shared.getCommentsForPost(postID: postID) { comments in
            self.postComments.append(contentsOf: comments.map { comment in
                CommentViewModel(comment: comment)
            })
            completion()
        }
    }

    func deleteComment(commentID: String, postID: String, postAuthorID: String, completion: @escaping () -> Void) {
        CommentSystemService.shared.deleteComment(postID: postID, commentID: commentID) {
            ActivitySystemService.shared.removeCommentEventForPost(commentID: commentID, postAuthorID: postAuthorID)
            completion()
        }
    }
}
