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

}
