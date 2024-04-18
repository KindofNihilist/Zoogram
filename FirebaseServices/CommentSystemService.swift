//
//  CommentsService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 01.02.2023.
//

import Foundation
import FirebaseDatabase

protocol CommentSystemServiceProtocol {
    typealias CommentsCount = Int

    func createCommentUID() -> String
    func postComment(for postID: String, comment: PostComment, completion: @escaping (VoidResult) -> Void)
    func deleteComment(postID: String, commentID: String, completion: @escaping (VoidResult) -> Void)
    func getCommentsForPost(postID: String, completion: @escaping (Result<[PostComment], Error>) -> Void)
    func getCommentsCountForPost(postID: String, completion: @escaping(Result<CommentsCount, Error>) -> Void)
}

class CommentSystemService: CommentSystemServiceProtocol {

    static let shared = CommentSystemService()

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    typealias CommentsCount = Int

    func createCommentUID() -> String {
        return databaseRef.child("PostComments").childByAutoId().key!
    }

    func postComment(for postID: String, comment: PostComment, completion: @escaping (VoidResult) -> Void) {
        let databaseKey = "PostComments/\(postID)/\(comment.commentID)"
        let commentDictionary = comment.dictionary

        databaseRef.child(databaseKey).setValue(commentDictionary) { error, _ in
            if let error = error {
                completion(.failure(ServiceError.couldntPostAComment))
            } else {
                completion(.success)
            }
        }

    }

    func deleteComment(postID: String, commentID: String, completion: @escaping (VoidResult) -> Void) {
        let databaseKey = "PostComments/\(postID)/\(commentID)"

        databaseRef.child(databaseKey).removeValue { error, _ in
            if let error = error {
                completion(.failure(ServiceError.couldntDeleteAComment))
            } else {
                completion(.success)
            }
        }
    }

    func getCommentsForPost(postID: String, completion: @escaping (Result<[PostComment], Error>) -> Void) {
        let databaseKey = "PostComments/\(postID)"
        let dispatchGroup = DispatchGroup()
        var comments = [PostComment]()

        databaseRef.child(databaseKey).queryOrderedByKey().getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadData))
                return
            } else if let snapshot = snapshot {

                for (index, snapshotChild) in snapshot.children.enumerated() {
                    guard let commentSnapshot = snapshotChild as? DataSnapshot,
                          let commentDictionary = commentSnapshot.value as? [String: Any]
                    else {
                        completion(.failure(ServiceError.snapshotCastingError))
                        return
                    }
                    dispatchGroup.enter()
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: commentDictionary as Any)
                        let decodedComment = try JSONDecoder().decode(PostComment.self, from: jsonData)
                        comments.append(decodedComment)
                        UserDataService.shared.getUser(for: decodedComment.authorID) { result in
                            switch result {
                            case .success(let commentAuthor):
                                comments[index].author = commentAuthor
                            case .failure(let error):
                                completion(.failure(ServiceError.couldntLoadData))
                                return
                            }
                            dispatchGroup.leave()
                        }
                    } catch {
                        completion(.failure(ServiceError.jsonParsingError))
                        return
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    completion(.success(comments))
                }
            }
        }
    }

    func getCommentsCountForPost(postID: String, completion: @escaping(Result<CommentsCount, Error>) -> Void) {
        let databaseKey = "PostComments/\(postID)"

        databaseRef.child(databaseKey).getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadData))
                print(error)
                return
            } else if let snapshot = snapshot {
                let commentsCount = Int(snapshot.childrenCount)
                completion(.success(commentsCount))
            }
        } 
    }
}
