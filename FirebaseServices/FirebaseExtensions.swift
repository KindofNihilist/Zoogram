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

enum VoidResultWithErrorDescription {
    case success
    case failure(ErrorDescription)
}

enum StorageKeys: String {
    case users = "Users/"
    case posts = "Posts/"
    case postsLikes = "PostsLikes/"
    case profilePictures = "/ProfilePictues/"
    case images = "Images/"
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
        let jsonData = try JSONSerialization.data(withJSONObject: value)
        let object = try JSONDecoder().decode(ZoogramUser.self, from: jsonData)
        return object
    }
}


