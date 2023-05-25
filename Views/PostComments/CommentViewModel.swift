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


    init(comment: PostComment) {
        self.commentID = comment.commentID
        self.authorID = comment.authorID
        self.commentText = comment.commentText
        self.datePostedText = comment.datePosted.timeAgoDisplay()
        self.author = comment.author
    }

    init(commentID: String, authorID: String, commentText: String, datePostedText: String, author: ZoogramUser) {
        self.commentID = commentID
        self.authorID = authorID
        self.commentText = commentText
        self.datePostedText = datePostedText
        self.author = author
    }

    static func createPostCaptionForCommentArea(with postViewModel: PostViewModel?) -> CommentViewModel? {
        guard let postViewModel = postViewModel else {
            return nil
        }
        let postCaption = CommentViewModel(
            commentID: "",
            authorID: postViewModel.author.userID,
            commentText: postViewModel.unAttributedPostCaption!,
            datePostedText: postViewModel.timeSincePostedTitle,
            author: postViewModel.author)
        return postCaption
    }
}
