//
//  NewPostService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.12.2022.
//

import Foundation
import FirebaseDatabase

class UserPostsService {
    
    static let shared = UserPostsService()
    
    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()
    
    private let currentUserID = AuthenticationManager.shared.getCurrentUserUID()
    
    func createPostUID() -> String {
        return databaseRef.child("Posts").childByAutoId().key!
    }
    
    typealias PostCount = Int
    
    typealias PhotoURLString = String
    
    //MARK: Create post
    func insertNewPost(post: UserPost, completion: @escaping (Result<Void, Error>) -> Void) {
        let userID = AuthenticationManager.shared.getCurrentUserUID()
        let postDictionary = post.createDictionary()
        let databaseKey = "Posts/\(userID)/\(post.postID)"
        
        
        databaseRef.child(databaseKey).setValue(postDictionary) { error, _ in
            if error == nil {
                completion(.success(Void()))
            } else {
                print("failed to insert post: \(error)")
                completion(.failure(error!))
            }
        }
    }
    
    func fanoutPost(post: UserPost, completion: @escaping () -> Void) {
        let uid = AuthenticationManager.shared.getCurrentUserUID()
        
        databaseRef.child("Followers/\(uid)").observeSingleEvent(of: .value) { followersSnapshot in
            
            let followersData = followersSnapshot.value as! [String: AnyObject]
            let followers = followersData.keys
            let postDictionary = post.createDictionary()
            print("Followers keys:", followers)
            var fanoutObj = [String : Any]()
            // write to each follower's timeline
            followers.forEach { follower in
                fanoutObj["/Timelines/\(follower)/\(post.postID)"] = postDictionary
            }
            
            fanoutObj["/Timelines/\(uid)/\(post.postID)"] = postDictionary
            print("Fanout object:", fanoutObj)
            
            self.databaseRef.updateChildValues(fanoutObj) { error, _ in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("succesfully fanned out the data")
                    completion()
                }
            }
        }
    }
    
    
    
    func uploadUserPostPhoto(post: PostViewModel, photo: UIImage, completion: @escaping (PhotoURLString) -> Void) {
        let fileName = "\(post.postID)_post.png"
        
        StorageManager.shared.uploadPostPhoto(photo: photo, fileName: fileName) { result in
            
            switch result {
                
            case .success(let photoURL):
                completion(photoURL.absoluteString)
                return
                
            case .failure(let error):
                print(error)
            }
        }
    }
    
    
    //MARK: Delete Post
    
    func deletePost(post: PostViewModel, completion: @escaping () -> Void) {
        let userID = AuthenticationManager.shared.getCurrentUserUID()
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        databaseRef.child("Posts/\(userID)/\(post.postID)").removeValue { error, _ in
            if let error = error {
                print(error.localizedDescription)
            } else {
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.enter()
        databaseRef.child("PostComments/\(post.postID)").removeValue { error, _ in
            if let error = error {
                print(error.localizedDescription)
            } else {
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.enter()
        databaseRef.child("PostsLikes/\(post.postID)").removeValue { error, _ in
            if let error = error {
                
                print(error.localizedDescription)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        
        StorageManager.shared.deletePostPhoto(photoURL: post.postImageURL) { result in
            switch result {
            case .success(_):
                print("Successfully deleted post photo")
            case .failure(let error):
                print(error.localizedDescription)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        deletePostFromFollowersTimeline(postID: post.postID) { error in
            if let error = error {
                print("Couldn't delete post from timelines", error.localizedDescription)
            } else {
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.enter()
        ActivityService.shared.removePostRelatedActivityEvents(postID: post.postID) {
            print("Removed related activity events")
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }
    
    func deletePostFromFollowersTimeline(postID: String, completion: @escaping (Error?) -> Void) {
        let uid = AuthenticationManager.shared.getCurrentUserUID()
        let followersRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()
        
        followersRef.child("Followers/\(uid)").observeSingleEvent(of: .value) { followersSnapshot in
            let followersDictionary = followersSnapshot.value as! [String: AnyObject]
            let followers = followersDictionary.keys
            var postsToDelete = [String: Any]()
            
            followers.forEach { follower in
                postsToDelete["/Timelines/\(follower)/\(postID)"] = NSNull()
            }
            
            postsToDelete["/Timelines/\(uid)/\(postID)"] = NSNull()
            
            self.databaseRef.updateChildValues(postsToDelete) { error, _ in
                if let error = error {
                    completion(error)
                } else {
                    print(followers)
                    print("Posts removed from followers timelines")
                    completion(nil)
                }
            }
        }
    }
    
    
    //MARK: Get Post
    func getPost(ofUser user: String, postID: String, completion: @escaping (UserPost) -> Void) {
        let databaseKey = "Posts/\(user)/\(postID)"
        
        databaseRef.child(databaseKey).observeSingleEvent(of: .value) { snapshot in
            guard let postDictionary = snapshot.value as? [String: Any] else {
                return
            }
            print("getting post")
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
                let decodedPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                UserService.shared.getUser(for: decodedPost.userID) { user in
                    decodedPost.author = user
                    print("Completing get post")
                    completion(decodedPost)
                }
            } catch { error
                print("catching error")
                print(error)
            }
        }
    }
    
    
    
    func observePostCount(for userID: String, completion: @escaping (PostCount) -> Void) {
        let databaseKey = "Posts/\(userID)/"
        
        databaseRef.child(databaseKey).observe(.value) { snapshot in
            completion(Int(snapshot.childrenCount))
        }
    }
    
    func getPosts(for userID: String, completion: @escaping ([UserPost], LastRetrievedPostKey) -> Void) {
        
        let databaseKey = "Posts/\(userID)/"
        
        databaseRef.child(databaseKey).queryOrderedByKey().queryLimited(toLast: 12).observeSingleEvent(of: .value) { snapshot in
            
            var retrievedPosts = [UserPost]()
            var lastPostKey = ""
            var postsAuthor = ZoogramUser()
            let dispatchGroup = DispatchGroup()
            
            for snapshotChild in snapshot.children.reversed() {
                
                guard let postSnapshot = snapshotChild as? DataSnapshot,
                      let postDictionary = postSnapshot.value as? [String: Any]
                else {
                    print("Couldn't cast snapshot as DataSnapshot")
                    return
                }
                dispatchGroup.enter()
                lastPostKey = postSnapshot.key
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
                    let decodedPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                    retrievedPosts.append(decodedPost)
                    dispatchGroup.leave()
                } catch {
                    print("Couldn't create UserPost from postDictionary")
                }
            }
            
            dispatchGroup.enter()
            UserService.shared.getUser(for: userID) { author in
                postsAuthor = author
                dispatchGroup.leave()
            }
            
            dispatchGroup.notify(queue: .main) {
                for post in retrievedPosts {
                    post.author = postsAuthor
                }
                completion(retrievedPosts, lastPostKey)
            }
        }
    }
    
    func getMorePosts(after postKey: String, for userID: String, completion: @escaping ([UserPost], LastRetrievedPostKey) -> Void) {
        
        let databaseKey = "Posts/\(userID)/"
        
        databaseRef.child(databaseKey).queryOrderedByKey().queryEnding(beforeValue: postKey).queryLimited(toLast: 9).observeSingleEvent(of: .value) { snapshot in
            
            var lastRetrievedPostKey = ""
            var retrievedPosts = [UserPost]()
            var postsAuthor = ZoogramUser()
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
                    retrievedPosts.append(decodedPost)
                    dispatchGroup.leave()
                } catch {
                    print("Couldn't decode post")
                }
            }
            
            dispatchGroup.enter()
            UserService.shared.getUser(for: userID) { author in
                postsAuthor = author
                dispatchGroup.leave()
            }
            
            dispatchGroup.notify(queue: .main) {
                for post in retrievedPosts {
                    post.author = postsAuthor
                }
                completion(retrievedPosts, lastRetrievedPostKey)
            }
        }
    }
}
