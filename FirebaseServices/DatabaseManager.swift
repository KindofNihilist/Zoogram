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
    
   public func insertNewUser(with user: ZoogramUser, completion: @escaping (Bool) -> Void) {
       let userID = AuthenticationManager.shared.getCurrentUserUID()
       
       let userDictionary = user.createDictionary()
       
        let databaseKey = "Users/\(userID)"
    
        database.child(databaseKey).setValue(userDictionary) { error, _ in
            if error == nil {
                // succeeded
                print("succesfully inserted user")
                completion(true)
            } else {
                // failed
                print("failed to insert data: \(error)")
                completion(false)
            }
        }
    }
    
    public func insertNewPost(post: UserPost, completion: @escaping (Bool) -> Void) {
        let userID = AuthenticationManager.shared.getCurrentUserUID()
        
        let postDictionary = post.createDictionary()
        
        let databaseKey = "Posts/\(userID)/"
    
        
        database.child(databaseKey).childByAutoId().setValue(postDictionary) { error, _ in
            if error == nil {
                print("successfully inserted post")
                completion(true)
            } else {
                print("failed to insert post: \(error)")
                completion(false)
            }
        }
    }
    
    public func getPosts(for userID: String, completion: @escaping ([UserPost], String) -> Void) {
        
        let databaseKey = "Posts/\(userID)/"
        
        database.child(databaseKey).queryOrderedByKey().queryLimited(toLast: 12).observe(.value) { snapshot in
            
            var retrievedPosts = [UserPost]()
            var lastSeenPostKey = ""
            
            for snapshotChild in snapshot.children.reversed() {
                
                guard let postSnapshot = snapshotChild as? DataSnapshot,
                      let postDictionary = postSnapshot.value as? [String: Any]
                else {
                    print("Couldn't cast snapshot as DataSnapshot")
                    return
                }
                
                lastSeenPostKey = postSnapshot.key
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
                    let decodedPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                    retrievedPosts.append(decodedPost)
                } catch {
                    print("Couldn't create UserPost from postDictionary")
                }
            }
            
            completion(retrievedPosts, lastSeenPostKey)
        }
    }
    
    public func getMorePosts(after postKey: String, for userID: String, completion: @escaping ([UserPost], String) -> Void) {
        
        let databaseKey = "Posts/\(userID)/"
        
        database.child(databaseKey).queryOrderedByKey().queryEnding(atValue: postKey).queryLimited(toLast: 9).observe(.value) { snapshot in
            
            var lastDownloadedPostKey = ""
            var downloadedPosts = [UserPost]()
            
            for snapshotChild in snapshot.children.reversed() {
                
                guard let postSnapshot = snapshotChild as? DataSnapshot,
                      let postDictionary = postSnapshot.value as? [String: Any]
                else {
                    print("Couldn't cast snapshot as DataSnapshot")
                    return
                }
                
                lastDownloadedPostKey = postSnapshot.key
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
                    let decodedPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                    downloadedPosts.append(decodedPost)
                } catch {
                    print("Couldn't decode post")
                }
            }
            completion(downloadedPosts, lastDownloadedPostKey)
        }
        
    }
    
    

    public func searchUserWith(username: String, completion: @escaping ([ZoogramUser]) -> Void) {

        let query = database.child("Users").queryOrdered(byChild: "username").queryStarting(atValue: username).queryEnding(atValue: "\(username)~")
        
        query.observe(.value) { snapshot in
            print(snapshot)
            
            var foundUsers = [ZoogramUser]()
            
            for snapshotChild in snapshot.children {
                
                guard let userSnapshot = snapshotChild as? DataSnapshot,
                      let userDictionary = userSnapshot.value as? [String: Any]
                else {
                    print("Couldn't convert snapshot to dictionary")
                    return
                }
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: userDictionary as Any)
                    let decodedUser = try JSONDecoder().decode(ZoogramUser.self, from: jsonData)
                    foundUsers.append(decodedUser)
                } catch {
                    print("Couldn't decode user")
                }
            }
            completion(foundUsers)
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
    
    public func checkIfUsernameIsAvailable(username: String, completion: @escaping (Bool) -> Void) {
        let query = database.child("Users").queryOrdered(byChild: "username").queryEqual(toValue: username)
        query.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    
    public func updateUserProfile(with values: [String: Any], completion: @escaping () -> Void) {
        let uid = AuthenticationManager.shared.getCurrentUserUID()
        
        if !values.isEmpty {
            database.child("Users/\(uid)").updateChildValues(values)
            completion()
        }
    }
    
    public func updateUserProfilePicture(newProfilePic: UIImage, completion: @escaping () -> Void = {}) {
        let uid = AuthenticationManager.shared.getCurrentUserUID()
        
        StorageManager.shared.uploadUserProfilePhoto(for: uid, with: newProfilePic, fileName: "\(AuthenticationManager.shared.getCurrentUserUID())_ProfilePicture.png") { [weak self] result in
            
            switch result {
                
            case .success(let pictureURL):
                self?.database.child("Users/\(uid)").updateChildValues(["profilePhotoURL" : pictureURL])
                completion()
                return
                
            case .failure(let error):
                print(error)
            }
        }
    }
    
    public func uploadUserPhotoPost(post: UserPost, photo: UIImage, completion: @escaping (String) -> Void) {
        let userID = AuthenticationManager.shared.getCurrentUserUID()
        let fileName = "\(post.postID)_post.png"
        
        StorageManager.shared.uploadPostPhoto(photo: photo, fileName: fileName) { result in
            
            switch result {
                
            case .success(let photoURL):
                completion(photoURL)
                return
                
            case .failure(let error):
                print(error)
            }
        }
    }
    
}

enum storageKeys: String {
    case users = "Users/"
    case posts = "Posts/"
    case profilePictures = "/ProfilePictues/"
    case images = "Images/"
}

enum storageError: Error {
    case errorObtainingSnapshot
    case couldNotMapSnapshotValue
}
