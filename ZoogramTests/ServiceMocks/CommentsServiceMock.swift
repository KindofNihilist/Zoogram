//
//  CommentsServiceMock.swift
//  ZoogramTests
//
//  Created by Artem Dolbiiev on 10.07.2024.
//

import Foundation
@testable import Zoogram

final class CommentsServiceMock: CommentSystemServiceProtocol {
    func createCommentUID() -> String {
        return ""
    }
    
    func postComment(for postID: String, comment: Zoogram.PostComment) async throws {
        return
    }
    
    func deleteComment(postID: String, commentID: String) async throws {
        return
    }
    
    func getCommentsForPost(postID: String) async throws -> [Zoogram.PostComment] {
        return [PostComment(commentID: "fakeCommentID", authorID: "fakeAuthorID", commentText: "Lorem Ipsum and stuff", datePosted: Date())]
    }
    
    func getCommentsCountForPost(postID: String) async throws -> Int {
        return 1
    }
}
