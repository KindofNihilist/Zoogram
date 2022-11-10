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
    
    private let databaseItself = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app")
    
    private let database = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()
    
    
    //MARK: User related methods
    
    func insertNewUser(with user: ZoogramUser, completion: @escaping (Bool) -> Void) {
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
    
    func searchUserWith(username: String, completion: @escaping ([ZoogramUser]) -> Void) {
        
        let query = database.child("Users").queryOrdered(byChild: "username").queryStarting(atValue: username).queryEnding(atValue: "\(username)~")
        
        query.observeSingleEvent(of: .value) { snapshot in
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
    
    func getUser(for userID: String, completion: @escaping (ZoogramUser) -> Void) {
        
        let path = storageKeys.users.rawValue + userID
        
        self.database.child(path).observeSingleEvent(of: .value) { snapshot in
            
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
    
    func checkIfUsernameIsAvailable(username: String, completion: @escaping (Bool) -> Void) {
        let query = database.child("Users").queryOrdered(byChild: "username").queryEqual(toValue: username)
        query.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    //MARK: Follow system methods
    
    func getFollowersNumber(for uid: String, completion: @escaping (Int) -> Void) {
        
        let databaseKey =  "Followers/\(uid)"
        
        database.child(databaseKey).observeSingleEvent(of: .value) { snapshot in
            completion(Int(snapshot.childrenCount))
        }
        
        
    }
    
    func getFollowingNumber(for uid: String, completion: @escaping (Int) -> Void) {
        
        let databaseKey =  "Following/\(uid)"
        
        database.child(databaseKey).observeSingleEvent(of: .value) { snapshot in
            completion(Int(snapshot.childrenCount))
        }
    }
    
    func getFollowers(for uid: String, completion: @escaping ([ZoogramUser]) -> Void) {
        
        var followers = [ZoogramUser]()
        
        let databaseKey = "Followers/\(uid)"
        
        let dispatchGroup = DispatchGroup()
        database.child(databaseKey).observeSingleEvent(of: .value) { snapshot in
            
            for snapshotChild in snapshot.children {
                
                guard let snapshotChild = snapshotChild as? DataSnapshot,
                      let snapshotDictionary = snapshotChild.value as? [String : String],
                      let userID = snapshotDictionary.first?.value
                else {
                    print("Couldn't convert snapshot to dictionary")
                    return
                }
                dispatchGroup.enter()
                self.getUser(for: userID) { follower in
                    followers.append(follower)
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
                completion(followers)
            }
        }
    }
    
    func getFollowing(for uid: String, completion: @escaping ([ZoogramUser]) -> Void) {
        
        var followedUsers = [ZoogramUser]()
        
        let databaseKey = "Following/\(uid)"
        
        let dispatchGroup = DispatchGroup()
        database.child(databaseKey).observeSingleEvent(of: .value) { snapshot in
            
            for snapshotChild in snapshot.children {
                
                guard let snapshotChild = snapshotChild as? DataSnapshot,
                      let snapshotDictionary = snapshotChild.value as? [String : String],
                      let userID = snapshotDictionary.first?.value
                else {
                    print("Couldn't convert snapshot to dictionary")
                    return
                }
                dispatchGroup.enter()
                self.getUser(for: userID) { followed in
                    followedUsers.append(followed)
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
                completion(followedUsers)
            }
        }
    }
    
    func checkFollowStatus(for uid: String, completion: @escaping (FollowStatus) -> Void) {
        let currentUserID = AuthenticationManager.shared.getCurrentUserUID()
        let query = database.child("Following/\(currentUserID)").queryOrdered(byChild: "userID").queryEqual(toValue: uid)
        query.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                print("User is followed:", snapshot)
                completion(.following)
            } else {
                print("User isn't followed:", snapshot)
                completion(.notFollowing)
            }
        }
    }
    
    func followUser(uid: String, completion: @escaping (Bool) -> Void) {
        let currentUserUID = AuthenticationManager.shared.getCurrentUserUID()
        
        let databaseKey = "Following/\(currentUserUID)/\(uid)"
        
        database.child(databaseKey).setValue(["userID": uid]) { error, _ in
            if error == nil {
                self.insertFollower(with: currentUserUID, to: uid) {
                    completion(true)
                }
            } else {
                completion(false)
            }
        }
        
    }
    
    func unfollowUser(uid: String, completion: @escaping (Bool) -> Void) {
        let currentUserUID = AuthenticationManager.shared.getCurrentUserUID()
        
        let databaseKey = "Following/\(currentUserUID)/\(uid)"
        
        database.child(databaseKey).removeValue { error, _ in
            if error == nil {
                self.removeFollower(with: currentUserUID, from: uid) {
                    completion(true)
                }
            } else {
                completion(false)
            }
        }
    }
    
    func insertFollower(with uid: String, to user: String, completion: @escaping () -> Void) {
        
        let databaseKey = "Followers/\(user)/\(uid)"
        
        database.child(databaseKey).setValue(["userID": uid]) { error, _ in
            if error == nil {
                completion()
            }
        }
    }
    
    func removeFollower(with uid: String, from user: String, completion: @escaping () -> Void) {
        
        let databaseKey = "Followers/\(user)/\(uid)"
        
        database.child(databaseKey).removeValue { error, _ in
            if error == nil {
                completion()
            }
        }
    }
    
    func forcefullyRemoveFollower(uid: String, completion: @escaping (Bool) -> Void) {
        let currentUserUID = AuthenticationManager.shared.getCurrentUserUID()
        
        let databaseKey = "Following/\(uid)/\(currentUserUID)"
        
        database.child(databaseKey).removeValue { error, _ in
            if error == nil {
                self.removeFollower(with: uid, from: currentUserUID) {
                    completion(true)
                }
            }
        }
    }
    
    func undoForcefullRemoval(ofUser uid: String, completion: @escaping (Bool) -> Void) {
        let currentUserUID = AuthenticationManager.shared.getCurrentUserUID()
        
        let databaseKey = "Following/\(uid)/\(currentUserUID)"
        
        database.child(databaseKey).setValue(["userID" : currentUserUID]) { error, _ in
            if error == nil {
                self.insertFollower(with: uid, to: currentUserUID) {
                    completion(true)
                }
            }
        }
    }
    
    
    //MARK: User Profile edditing
    
    func updateUserProfile(with values: [String: Any], completion: @escaping () -> Void) {
        let uid = AuthenticationManager.shared.getCurrentUserUID()
        
        if !values.isEmpty {
            database.child("Users/\(uid)").updateChildValues(values)
            completion()
        }
    }
    
    func updateUserProfilePicture(newProfilePic: UIImage, completion: @escaping () -> Void = {}) {
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
    
    //MARK: Post related methods
    
    func createPostUID() -> String {
        return database.child("Posts").childByAutoId().key!
    }
    
    func insertNewPost(post: UserPost, completion: @escaping (Result<String, Error>) -> Void) {
        let userID = AuthenticationManager.shared.getCurrentUserUID()
        let postDictionary = post.createDictionary()
        let databaseKey = "Posts/\(userID)/\(post.postID)"
        
        
        database.child(databaseKey).setValue(postDictionary) { error, _ in
            if error == nil {
                self.incrementPostCount(for: userID)
                completion(.success("Succesfully created post"))
            } else {
                print("failed to insert post: \(error)")
                completion(.failure(error!))
            }
        }
    }
    
    func deletePost(id: String, completion: @escaping () -> Void) {
        let userID = AuthenticationManager.shared.getCurrentUserUID()
        
        let databaseKey = "Posts/\(userID)/\(id)"
        
        database.child(databaseKey).removeValue { error, _ in
            if error == nil {
                print("Post deleted successfully")
                self.decrementPostCount(for: userID)
                completion()
            }
        }
    }
    
    func incrementPostCount(for userID: String) {
        let databaseKey = "Users/\(userID)/posts"
        print(databaseKey)
        print("Increment posts count")
        database.child(databaseKey).setValue(FirebaseDatabase.ServerValue.increment(1))
    }
    
    func decrementPostCount(for userID: String) {
        let databaseKey = "Users/\(userID)/posts"
        print(databaseKey)
        print("Increment posts count")
        database.child(databaseKey).setValue(FirebaseDatabase.ServerValue.increment(-1))
    }
    
    func getPosts(for userID: String, completion: @escaping ([UserPost], String) -> Void) {
        
        let databaseKey = "Posts/\(userID)/"
        
        database.child(databaseKey).queryOrderedByKey().queryLimited(toLast: 12).observeSingleEvent(of: .value) { snapshot in
            
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
    
    func getMorePosts(after postKey: String, for userID: String, completion: @escaping ([UserPost], String) -> Void) {
        
        let databaseKey = "Posts/\(userID)/"
        
        database.child(databaseKey).queryOrderedByKey().queryEnding(beforeValue: postKey).queryLimited(toLast: 9).observeSingleEvent(of: .value) { snapshot in
            
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
    
    func uploadUserPostPhoto(post: UserPost, photo: UIImage, completion: @escaping (String) -> Void) {
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
    
    //MARK: Like system methods
    
    func checkIfPostIsLiked(postID: String, completion: @escaping (PostLikeState) -> Void) {
        let userID = AuthenticationManager.shared.getCurrentUserUID()
        
        let databaseKey = "PostsLikes/\(postID)/"
        
        let query = database.child(databaseKey).queryOrdered(byChild: "userID").queryEqual(toValue: userID)
        print("inside like check", databaseKey)
        
        query.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                completion(.liked)
            } else {
                completion(.notLiked)
            }
        }
    }
    
    func getLikesCountForPost(id: String, completion: @escaping (Int) -> Void) {
        
        let databaseKey = "PostsLikes/\(id)"
        
        database.child(databaseKey).observe(.value) { snapshot in
            completion(Int(snapshot.childrenCount))
        }
    }
    
    func getUsersLikedForPost(id: String, completion: @escaping () -> Void) {
        
    }
    
    func likePost(postID: String, completion: @escaping (Result<String, Error>) -> Void) {
        let userID = AuthenticationManager.shared.getCurrentUserUID()
        
        let databaseKey = "PostsLikes/\(postID)/\(userID)"
        print("inside post like method", databaseKey)
        print(databaseKey)
        database.child(databaseKey).setValue(["userID" : userID]) { error, _ in
            if error == nil {
                completion(.success("liked post \(postID)"))
            } else {
                completion(.failure(error!))
            }
        }
    }
    
    func removePostLike(postID: String, completion: @escaping (Result<String,Error>) -> Void) {
        let userID = AuthenticationManager.shared.getCurrentUserUID()
        
        let databaseKey = "PostsLikes/\(postID)/\(userID)"
        
        database.child(databaseKey).removeValue { error, _ in
            if error == nil {
                completion(.success("remove like from \(postID)"))
            } else {
                completion(.failure(error!))
            }
        }
    }
    
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
