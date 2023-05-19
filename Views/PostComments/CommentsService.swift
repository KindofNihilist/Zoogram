//
//  CommentsService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 17.05.2023.
//

import Foundation

protocol CommentsService {
    var postID: String { get set }
    var postAuthorID: String { get set }
    func getComments(completion: @escaping ([PostComment]) -> Void)
    func postComment(comment: PostComment, completion: @escaping (PostComment) -> Void)
    func deleteComment(commentID: String, completion: @escaping () -> Void)
}
