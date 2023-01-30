//
//  DatabaseManager.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//
import FirebaseDatabase
import SwiftUI

final public class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app")
    
    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()
    
    
    //MARK: User related methods
    
    
    
   
    //MARK: Like system methods
    
    
}

enum storageKeys: String {
    case users = "Users/"
    case posts = "Posts/"
    case postsLikes = "PostsLikes/"
    case profilePictures = "/ProfilePictues/"
    case images = "Images/"
}

enum storageError: Error {
    case errorObtainingSnapshot
    case couldNotMapSnapshotValue
    case errorCreatingAPost
}
