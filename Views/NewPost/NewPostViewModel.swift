//
//  NewPostViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 14.10.2022.
//

import UIKit
import Firebase

class NewPostViewModel {
    
    var followersRef: DatabaseReference!
    var followersSnap: DataSnapshot!
    
    var photo: UIImage
    var caption: String
    var post: UserPost!
    
    
    
    init(photo: UIImage = UIImage(), caption: String = "") {
        self.photo = photo
        self.caption = caption
    }
    
    func getSnapshotOfFollowers() {
        let uid = AuthenticationManager.shared
            .getCurrentUserUID()
        followersRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()
        followersRef.child("Followers/\(uid)").observe(.value) { self.followersSnap = $0 }
    }
    
    func createPost(caption: String) {
        let userUID = AuthenticationManager.shared.getCurrentUserUID()
        let postUID = UserPostsService.shared.createPostUID()
        post = UserPost(userID: userUID,
                        postID: postUID,
                        photoURL: "",
                        caption: caption,
                        likeCount: 0,
                        commentsCount: 0,
                        postedDate: Date())
    }
    
    func preparePhotoForPosting(photoToCompress: UIImage) {
        ImageCompressor.compress(image: photoToCompress, maxByte: 800000) { compressedImage in
            if let image = compressedImage {
                self.photo = image
            }
        }
    }
    
    func makeAPost(caption: String, completion: @escaping (Bool) -> Void) {
        self.createPost(caption: caption)
        let fileName = "\(post.postID)_post.png"
        
        let dispatchGroup = DispatchGroup()
        
        StorageManager.shared.uploadPostPhoto(photo: photo, fileName: fileName) { result in
            
            switch result {
                
            case .success(let photoURL):
                
                self.post.photoURL = photoURL.absoluteString
                
                UserPostsService.shared.insertNewPost(post: self.post) { result in
                    
                    switch result {
                        
                    case .success(let message):
                        print(message)
                        
                        dispatchGroup.enter()
                        UserPostsService.shared.fanoutPost(post: self.post) {
                            dispatchGroup.leave()
                        }
                        
                        dispatchGroup.enter()
                        UserPostsService.shared.getPostCount(for: currentUserID()) { postsCount in
                            print("got posts count on post creation. Post count: \(postsCount)")
                            if postsCount == 1 {
                                UserService.shared.changeHasPostsStatus(hasPostsStatus: true) {
                                    dispatchGroup.leave()
                                }
                            } else {
                                dispatchGroup.leave()
                            }
                        }
                        
                        dispatchGroup.notify(queue: .main) {
                            completion(true)
                        }
                        
                        
                    case .failure(let error):
                        print(error)
                    }
                }
            case .failure(let error):
                completion(false)
                print(error)
            }
        }
    }
    
    
}
