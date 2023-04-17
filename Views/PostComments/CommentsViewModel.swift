//
//  CommentsViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 01.02.2023.
//

import Foundation

class CommentsViewModel {
    
    var postComments: [PostComment] = []
    
    func postComment(postID: String, postAuthorID: String, comment: String, completion: @escaping () -> Void) {
        guard !comment.isEmpty else {
            return
        }
        let commentUID = CommentsService.shared.createCommentUID()
        let currentUserID = AuthenticationManager.shared.getCurrentUserUID()
        
        let postComent = PostComment(commentID: commentUID, authorID: currentUserID, commentText: comment, datePosted: Date())
        CommentsService.shared.postComment(for: postID, comment: postComent) {
            
            //Adding activity event to user activity timeline
            let eventID = ActivityService.shared.createEventUID()
            let activityEvent = ActivityEvent(eventType: .postCommented, userID: postComent.authorID, postID: postID, eventID: eventID, date: Date(), text: postComent.commentText, commentID: commentUID)
            ActivityService.shared.addEventToUserActivity(event: activityEvent, userID: postAuthorID)
            
            //Receiveing newly made comment's author profile to append it to tableView
            UserService.shared.getUser(for: postComent.authorID) { author in
                postComent.author = author
                self.postComments.append(postComent)
                completion()
            }
        }
    }
    
    func getComments(for postID: String, completion: @escaping () -> Void) {
        CommentsService.shared.getCommentsForPost(postID: postID) { comments in
            self.postComments.append(contentsOf: comments)
            completion()
        }
    }
    
    func deleteComment(commentID: String, postID: String, postAuthorID: String, completion: @escaping () -> Void) {
        CommentsService.shared.deleteComment(postID: postID, commentID: commentID) {
            ActivityService.shared.removeCommentEventForPost(commentID: commentID, postAuthorID: postAuthorID)
            completion()
        }
    }
}
