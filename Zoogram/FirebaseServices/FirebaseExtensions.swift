//
//  FirebaseExtensions.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 30.09.2022.
//

import Foundation
import FirebaseDatabase

public typealias LastRetrievedPostKey = String

enum VoidResult {
    case success
    case failure(Error)
}

struct DatabaseKeys {
    static let users = "Users/"
    static let usernames = "UsernamesForLookup/"
    static let posts = "Posts/"
    static let postsLikes = "PostsLikes/"
    static let profilePictures = "/ProfilePictues/"
    static let images = "Images/"
    static let timelines = "Timelines/"
}

enum StorageError: Error {
    case errorObtainingSnapshot
    case couldNotMapSnapshotValue
    case errorCreatingAPost
    case couldntLoadImage
}

extension DataSnapshot {

    func decoded() throws -> ZoogramUser {
        let value = value
        let jsonData = try JSONSerialization.data(withJSONObject: value as Any)
        let object = try JSONDecoder().decode(ZoogramUser.self, from: jsonData)
        return object
    }
}
