//
//  CommentViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 18.05.2023.
//

import Foundation

class CommentViewModel {

    let commentID: String
    let authorID: String
    let commentText: String
    let datePostedText: String
    let author: ZoogramUser
    let canBeEdited: Bool
    var shouldBeMarkedUnseed: Bool = false

    init(comment: PostComment, canBeEdited: Bool) {
        self.commentID = comment.commentID
        self.authorID = comment.authorID
        self.commentText = comment.commentText
        self.datePostedText = comment.datePosted.timeAgoDisplay()
        self.canBeEdited = canBeEdited
        self.author = comment.author
    }

    init(commentID: String, authorID: String, commentText: String, datePostedText: String, canBeEdited: Bool, author: ZoogramUser) {
        self.commentID = commentID
        self.authorID = authorID
        self.commentText = commentText
        self.datePostedText = datePostedText
        self.canBeEdited = canBeEdited
        self.author = author
    }

    static func createPostCaptionForCommentArea(with postViewModel: PostViewModel?) -> CommentViewModel? {
        guard let postViewModel = postViewModel, let caption = postViewModel.unAttributedPostCaption else {
            return nil
        }
        let postCaption = CommentViewModel(
            commentID: "",
            authorID: postViewModel.author.userID,
            commentText: caption,
            datePostedText: postViewModel.timeSincePostedTitle,
            canBeEdited: false,
            author: postViewModel.author)
        return postCaption
    }
}
