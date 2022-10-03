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
    
    private let database = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()
    
    // Check if email and username is available
    public func checkIfUsernameIsTaken(with email: String, username: String, usernameTaken: @escaping (Bool) -> Void) {
        usernameTaken(false)
    }
    
   public func insertNewUser(with user: ZoogramUser, completion: @escaping (Bool) -> Void) {
        guard let userID = AuthenticationManager.currentUserUID else {
            return
        }
        let databaseKey = "Users/\(userID)"
        print(databaseKey)
        database.child(databaseKey).setValue([
            "profilePhotoURL": user.profilePhotoURL,
            "email": user.email,
            "phoneNumber": user.phoneNumber,
            "username": user.username,
            "name": user.name ?? "",
            "bio": user.bio ?? "",
            "birthday": user.birthday ?? "",
            "gender": user.gender ?? "",
            "following": user.following,
            "followers": user.followers,
            "posts": user.posts,
            "joinDate": user.joinDate
        ]) { error, _ in
            if error == nil {
                // succeeded
                print("succesfully inserted")
                completion(true)
                return
            } else {
                // failed
                print("failed to insert data with error \(error)")
                completion(false)
                return
            }
        }
    }
    
    
   public func getUser(for userID: String, completion: @escaping (ZoogramUser?) -> Void) {
       
        let path = storageKeys.users.rawValue + userID
    
        self.database.child(path).observe(.value) { snapshot in
    
            guard let value = snapshot.value as? [String: Any] else {
                return
            }
            
            do {
                let json = try JSONSerialization.data(withJSONObject: value as Any)
                let decodedUser = try JSONDecoder().decode(ZoogramUser.self, from: json)
                completion(decodedUser)
                
            } catch {
                print(error)
            }
        }
    }
    
    
    public func updateUserProfile(for userID: String, with values: [String: Any], profilePic: UIImage?, completion: @escaping () -> Void) {
        
        if !values.isEmpty {
            database.child("Users/\(userID)").updateChildValues(values)
        }
        
        if let image = profilePic, profilePic != nil {
            
            StorageManager.shared.uploadUserProfilePhoto(for: userID, with: image, fileName: "\(AuthenticationManager.currentUserEmail!)_ProfilePicture.png") { [weak self] result in
                
                switch result {
                    
                case .success(let pictureURL):
                    self?.database.child("Users/\(userID)").updateChildValues(["profilePhotoURL" : pictureURL])
                    completion()
                    return
                    
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
}

enum storageKeys: String {
    case users = "Users/"
    case profilePictures = "/ProfilePictues/"
    case images = "Images/"
}

enum storageError: Error {
    case errorObtainingSnapshot
    case couldNotMapSnapshotValue
}
