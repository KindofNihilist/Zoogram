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

    func checkIfPostIsLiked(postID: String) async throws -> LikeState
    func getLikesCountForPost(id: String) async throws -> LikesCount
    func likePost(postID: String) async throws
    func removeLikeFromPost(postID: String) async throws
}

class LikeSystemService: LikeSystemServiceProtocol {

    static let shared = LikeSystemService()

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()
    
    func checkIfPostIsLiked(postID: String) async throws -> LikeState {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let databaseKey = "PostsLikes/\(postID)/"
        let query = databaseRef.child(databaseKey).queryOrdered(byChild: "userID").queryEqual(toValue: currentUserID)

        let data = try await query.getData()
        return data.exists() ? .liked : .notLiked
    }
    
    func getLikesCountForPost(id: String) async throws -> LikesCount {
        let databaseKey = "PostsLikes/\(id)"

        do {
            let data = try await databaseRef.child(databaseKey).getData()
            return Int(data.childrenCount)
        } catch {
            throw ServiceError.couldntLoadData
        }
    }
    
    func likePost(postID: String) async throws {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let databaseKey = "PostsLikes/\(postID)/\(currentUserID)"
        do {
            try await databaseRef.child(databaseKey).setValue(["userID" : currentUserID])
        } catch {
            throw ServiceError.couldntCompleteTheAction
        }
    }
    
    func removeLikeFromPost(postID: String) async throws {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let databaseKey = "PostsLikes/\(postID)/\(currentUserID)"
        do {
            try await databaseRef.child(databaseKey).removeValue()
        } catch {
            throw ServiceError.couldntCompleteTheAction
        }
    }
}
