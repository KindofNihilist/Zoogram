//
//  NewPostService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.12.2022.
//

import Foundation
import FirebaseDatabase

class UserPostService {
    
    static let shared = UserPostService()
    
    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()
    
    
    func createPostUID() -> String {
        return databaseRef.child("Posts").childByAutoId().key!
    }
    
    func insertNewPost(post: UserPost, completion: @escaping (Result<String, Error>) -> Void) {
        let userID = AuthenticationManager.shared.getCurrentUserUID()
        let postDictionary = post.createDictionary()
        let databaseKey = "Posts/\(userID)/\(post.postID)"
        
        
        databaseRef.child(databaseKey).setValue(postDictionary) { error, _ in
            if error == nil {
//                self.incrementPostCount(for: userID)
                completion(.success("Succesfully created post"))
            } else {
                print("failed to insert post: \(error)")
                completion(.failure(error!))
            }
        }
    }
    
    func fanoutPost(uid: String, followersSnapshot: DataSnapshot, post: UserPost, completion: () -> Void) -> [String : Any] {
        let followersData = followersSnapshot.value as! [String: AnyObject]
        let followers = followersData.keys
        let postDictionary = post.createDictionary()
        print("Followers keys:", followers)
        var fanoutObj = [String : Any]()
          // write to each follower's timeline
        followers.forEach { key in fanoutObj["/Timelines/\(key)/\(post.postID)"] = postDictionary }
        
        fanoutObj["/Timelines/\(uid)/\(post.postID)"] = postDictionary
        
        print("Fanout object:", fanoutObj)
        
        databaseRef.updateChildValues(fanoutObj) { err, _ in
            if err != nil {
                print("failed", err)
            } else {
                print("succesfully fanned out the data")
            }
        }
        completion()
        return fanoutObj
    }
    
    func deletePost(id: String, completion: @escaping () -> Void) {
        let userID = AuthenticationManager.shared.getCurrentUserUID()
        
        let databaseKey = "Posts/\(userID)/\(id)"
        
        databaseRef.child(databaseKey).removeValue { error, _ in
            if error == nil {
                print("Post deleted successfully")
//                self.decrementPostCount(for: userID)
                completion()
            }
        }
    }
    
    func getPostCount(for userID: String, completion: @escaping (Int) -> Void) {
        let databaseKey = "Posts/\(userID)/"
        
        databaseRef.child(databaseKey).observe(.value) { snapshot in
            completion(Int(snapshot.childrenCount))
        }
    }
    
    func getPosts(for userID: String, completion: @escaping ([UserPost], String) -> Void) {
        
        let databaseKey = "Posts/\(userID)/"
        
        databaseRef.child(databaseKey).queryOrderedByKey().queryLimited(toLast: 12).observe(.value) { snapshot in
            
            var retrievedPosts = [UserPost]()
            var lastSeenPostKey = ""
            let dispatchGroup = DispatchGroup()
            
            for snapshotChild in snapshot.children.reversed() {
                
                guard let postSnapshot = snapshotChild as? DataSnapshot,
                      let postDictionary = postSnapshot.value as? [String: Any]
                else {
                    print("Couldn't cast snapshot as DataSnapshot")
                    return
                }
                dispatchGroup.enter()
                lastSeenPostKey = postSnapshot.key
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
                    let decodedPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                    
                    UserService.shared.getUser(for: decodedPost.userID) { postAuthor in
                        decodedPost.author = postAuthor
                        retrievedPosts.append(decodedPost)
                        dispatchGroup.leave()
                    }
                    
                } catch {
                    print("Couldn't create UserPost from postDictionary")
                }
            }
            dispatchGroup.notify(queue: .main) {
                completion(retrievedPosts, lastSeenPostKey)
            }
        }
    }
    
    func getMorePosts(after postKey: String, for userID: String, completion: @escaping ([UserPost], String) -> Void) {
        
        let databaseKey = "Posts/\(userID)/"
        
        databaseRef.child(databaseKey).queryOrderedByKey().queryEnding(beforeValue: postKey).queryLimited(toLast: 9).observe(.value) { snapshot in
            
            var lastRetrievedPostKey = ""
            var retrievedPosts = [UserPost]()
            let dispatchGroup = DispatchGroup()
            
            for snapshotChild in snapshot.children.reversed() {
                
                guard let postSnapshot = snapshotChild as? DataSnapshot,
                      let postDictionary = postSnapshot.value as? [String: Any]
                else {
                    print("Couldn't cast snapshot as DataSnapshot")
                    return
                }
                dispatchGroup.enter()
                lastRetrievedPostKey = postSnapshot.key
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
                    let decodedPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                    
                    UserService.shared.getUser(for: decodedPost.userID) { postAuthor in
                        decodedPost.author = postAuthor
                        retrievedPosts.append(decodedPost)
                        dispatchGroup.leave()
                    }
                } catch {
                    print("Couldn't decode post")
                }
            }
            dispatchGroup.notify(queue: .main) {
                completion(retrievedPosts, lastRetrievedPostKey)
            }
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
    
}
