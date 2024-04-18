//
//  LikeSystemServicce.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.12.2022.
//

import Foundation
import FirebaseDatabase

protocol LikeSystemServiceProtocol {
    typealias LikesCount = Int

    func checkIfPostIsLiked(postID: String, completion: @escaping (Result<LikeState, Error>) -> Void)
    func getLikesCountForPost(id: String, completion: @escaping (Result<LikesCount, Error>) -> Void)
    func likePost(postID: String, completion: @escaping (VoidResult) -> Void)
    func removeLikeFromPost(postID: String, completion: @escaping (VoidResult) -> Void)
}

class LikeSystemService: LikeSystemServiceProtocol {

    static let shared = LikeSystemService()

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()
    
    func checkIfPostIsLiked(postID: String, completion: @escaping (Result<LikeState, Error>) -> Void) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }
        let databaseKey = "PostsLikes/\(postID)/"
        let query = databaseRef.child(databaseKey).queryOrdered(byChild: "userID").queryEqual(toValue: currentUserID)

        query.getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadData))
                print(error)
                return
            } else if let snapshot = snapshot {

                if snapshot.exists() {
                    completion(.success(.liked))
                } else {
                    completion(.success(.notLiked))
                }
            }
        }
    }
    
    func getLikesCountForPost(id: String, completion: @escaping (Result<LikesCount, Error>) -> Void) {
        let databaseKey = "PostsLikes/\(id)"
        
        databaseRef.child(databaseKey).getData { error, snapshot in
            if let error = error {
                print(error)
                completion(.failure(ServiceError.couldntLoadData))
                return
            } else if let snapshot = snapshot {
                let likesCount = Int(snapshot.childrenCount)
                completion(.success(likesCount))
            }
        }
    }
    
    func likePost(postID: String, completion: @escaping (VoidResult) -> Void) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }
        let databaseKey = "PostsLikes/\(postID)/\(currentUserID)"

        databaseRef.child(databaseKey).setValue(["userID" : currentUserID]) { error, _ in
            if let error = error {
                completion(.failure(ServiceError.couldntCompleteTheAction))
            } else {
                completion(.success)
            }
        }
    }
    
    func removeLikeFromPost(postID: String, completion: @escaping (VoidResult) -> Void) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }
        let databaseKey = "PostsLikes/\(postID)/\(currentUserID)"

        databaseRef.child(databaseKey).removeValue { error, _ in
            if let error = error {
                completion(.failure(ServiceError.couldntCompleteTheAction))
            } else {
                completion(.success)
            }
        }
    }
}
