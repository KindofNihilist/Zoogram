//
//  CommentsService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 01.02.2023.
//

import Foundation
import FirebaseDatabase

class CommentSystemService {
    
    static let shared = CommentSystemService()
    
    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()
    
    typealias CommentsCount = Int
    
    func createCommentUID() -> String {
        return databaseRef.child("PostComments").childByAutoId().key!
    }
    
    func postComment(for postID: String, comment: PostComment, completion: @escaping () -> Void) {
        let databaseKey = "PostComments/\(postID)/\(comment.commentID)"
        
        let commentDictionary = comment.dictionary
        
        databaseRef.child(databaseKey).setValue(commentDictionary) { error, _ in
            if error == nil {
                completion()
                print("Succesfully posted a comment")
            } else {
                print("There was an error posting a comment")
            }
        }
        
    }
    
    func deleteComment(postID: String, commentID: String, completion: @escaping () -> Void) {
        let databaseKey = "PostComments/\(postID)/\(commentID)"
        
        databaseRef.child(databaseKey).removeValue { error, _ in
            if error == nil {
                completion()
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    func getCommentsForPost(postID: String, completion: @escaping ([PostComment]) -> Void) {
        let databaseKey = "PostComments/\(postID)"
        let dispatchGroup = DispatchGroup()
        var comments = [PostComment]()
        
        databaseRef.child(databaseKey).queryOrderedByKey().observeSingleEvent(of: .value) { snapshot in
            
            for snapshotChild in snapshot.children {
                
                guard let commentSnapshot = snapshotChild as? DataSnapshot,
                      let commentDictionary = commentSnapshot.value as? [String: Any]
                else {
                    return
                }
                dispatchGroup.enter()
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: commentDictionary as Any)
                    let decodedComment = try JSONDecoder().decode(PostComment.self, from: jsonData)
                    
                    UserService.shared.getUser(for: decodedComment.authorID) { commentAuthor in
                        decodedComment.author = commentAuthor
                        comments.append(decodedComment)
                        dispatchGroup.leave()
                    }
                } catch {
                    print("Error encountered while decoding post comment")
                }
            }
            dispatchGroup.notify(queue: .main) {
                completion(comments)
            }
        }
    }
    
    func getCommentsCountForPost(postID: String, completion: @escaping(CommentsCount) -> Void) {
        let databaseKey = "PostComments/\(postID)"
        
        databaseRef.child(databaseKey).observeSingleEvent(of: .value) { snapshot in
            completion(Int(snapshot.childrenCount))
        }
    }
}
