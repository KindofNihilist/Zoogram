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
    
    public func insertNewUser(with user: User, completion: @escaping (Bool) -> Void) {
        guard let userID = AuthenticationManager.currentUserUID else {
            return
        }
        let databaseKey = "Users/\(userID)"
        print(databaseKey)
        database.child(databaseKey).setValue([
            "profilePhotoURL": user.profilePhotoURL,
            "email": user.emailAdress,
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
    
    public func getUser(for userID: String, completion: @escaping (Result<User, Error>) -> Void) {
        let path = storageKeys.users.rawValue + userID
        database.child(path).observe(.value) { snapshot in
            guard let value = snapshot.value as? [String: Any] else {
                completion(.failure(storageError.errorObtainingSnapshot))
                return
            }
            print(value)
            guard let profilePhotoURL = value["profilePhotoURL"] as? String,
                  let email = value["email"] as? String,
                  let phoneNumber = value["phoneNumber"] as? String,
                  let username = value["username"] as? String,
                  let name = value["name"] as? String,
                  let bio = value["bio"] as? String,
                  let birthday = value["birthday"] as? String,
                  let gender = value["gender"] as? String,
                  let following = value["following"] as? Int,
                  let followers = value["followers"] as? Int,
                  let posts = value["posts"] as? Int,
                  let joinDate = value["joinDate"] as? Double else {
                      completion(.failure(storageError.couldNotMapSnapshotValue))
                      return
                  }
            let user = User(profilePhotoURL: profilePhotoURL,
                            emailAdress: email,
                            phoneNumber: phoneNumber,
                            username: username,
                            name: name,
                            bio: bio,
                            birthday: birthday,
                            gender: gender,
                            following: following,
                            followers: followers,
                            posts: posts,
                            joinDate: joinDate)
            print("Succesfully obtained user data")
            completion(.success(user))
        }
    }
    
    public func updateUserProfile(for userID: String, with values: [String: Any], profilePic: UIImage?) {
        if !values.isEmpty {
            database.child("Users/\(userID)").updateChildValues(values)
        }
        if let image = profilePic, profilePic != nil {
            StorageManager.shared.uploadUserProfilePhoto(for: userID, with: image, fileName: "\(AuthenticationManager.currentUserEmail!)_ProfilePicture.png") { [weak self] result in
                switch result {
                case .success(let pictureURL):
                    self?.database.child("Users/\(userID)").updateChildValues(["profilePhotoURL" : pictureURL])
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
