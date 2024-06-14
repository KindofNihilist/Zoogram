//
//  CommentsService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 01.02.2023.
//

import Foundation
@preconcurrency import FirebaseDatabase

protocol CommentSystemServiceProtocol: Sendable{
    typealias CommentsCount = Int

    func createCommentUID() -> String
    func postComment(for postID: String, comment: PostComment) async throws
    func deleteComment(postID: String, commentID: String) async throws
    func getCommentsForPost(postID: String) async throws -> [PostComment]
    func getCommentsCountForPost(postID: String) async throws -> Int
}

final class CommentSystemService: CommentSystemServiceProtocol {

    static let shared = CommentSystemService()

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    typealias CommentsCount = Int

    func createCommentUID() -> String {
        return databaseRef.child("PostComments").childByAutoId().key!
    }

    func postComment(for postID: String, comment: PostComment) async throws {
        let databaseKey = "PostComments/\(postID)/\(comment.commentID)"
        let commentDictionary = comment.dictionary
        do {
            try await databaseRef.child(databaseKey).setValue(commentDictionary)
        } catch {
            print("postComment error: ", error.localizedDescription)
            throw ServiceError.couldntPostAComment
        }
    }

    func deleteComment(postID: String, commentID: String) async throws {
        let databaseKey = "PostComments/\(postID)/\(commentID)"

        do {
            try await databaseRef.child(databaseKey).removeValue()
        } catch {
            throw ServiceError.couldntDeleteAComment
        }
    }

    func getCommentsForPost(postID: String) async throws -> [PostComment] {
        let databaseKey = "PostComments/\(postID)"
        var comments = [PostComment]()

        let query = databaseRef.child(databaseKey).queryOrderedByKey()

        do {
            let data = try await query.getData()

            for (index, snapshotChild) in data.children.enumerated() {
                guard let commentSnapshot = snapshotChild as? DataSnapshot,
                      let commentDictionary = commentSnapshot.value as? [String: Any]
                else {
                    throw ServiceError.snapshotCastingError
                }
                let jsonData = try JSONSerialization.data(withJSONObject: commentDictionary as Any)
                let decodedComment = try JSONDecoder().decode(PostComment.self, from: jsonData)
                comments.append(decodedComment)
                comments[index].author = try await UserDataService().getUser(for: decodedComment.authorID)
            }
            return comments
        } catch {
            throw ServiceError.couldntLoadComments
        }
    }

    func getCommentsCountForPost(postID: String) async throws -> Int {
        let databaseKey = "PostComments/\(postID)"

        do {
            let data = try await databaseRef.child(databaseKey).getData()
            return Int(data.childrenCount)
        } catch {
            throw ServiceError.couldntLoadData
        }
    }
}
