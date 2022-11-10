//
//  NewPostViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 14.10.2022.
//

import UIKit

class NewPostViewModel {
    
    var photo: UIImage
    var caption: String
    var post: UserPost!
    
    init(photo: UIImage = UIImage(), caption: String = "") {
        self.photo = photo
        self.caption = caption
    }
    
    func createPost(postType: UserPostType, caption: String) {
        let userUID = AuthenticationManager.shared.getCurrentUserUID()
        let postUID = DatabaseManager.shared.createPostUID()
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
    
    func makeAPost(postType: UserPostType, caption: String, completion: @escaping (Bool) -> Void) {
        
        self.createPost(postType: postType, caption: caption)
        let fileName = "\(post.postID)_post.png"
        
        StorageManager.shared.uploadPostPhoto(photo: photo, fileName: fileName) { result in
            
            switch result {
                
            case .success(let photoURL):
                self.post.photoURL = photoURL
                
                DatabaseManager.shared.insertNewPost(post: self.post) { result in
                    
                    switch result {
                        
                    case .success(let message):
                        print(message)
                        completion(true)
                        
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
