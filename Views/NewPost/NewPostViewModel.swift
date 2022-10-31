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
    let postUID: String
    
    init(photo: UIImage = UIImage(), caption: String = "") {
        self.photo = photo
        self.caption = caption
        self.postUID = UUID().uuidString
    }
    
    func createPost(postType: UserPostType, caption: String, photoURL: String) {
        let userUID = AuthenticationManager.shared.getCurrentUserUID()
        post = UserPost(userID: userUID,
                        postID: postUID,
                        photoURL: photoURL,
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
        let fileName = "\(postUID)_post.png"
        StorageManager.shared.uploadPostPhoto(photo: photo, fileName: fileName) { result in
            
            switch result {
                
            case .success(let photoURL):
                
                self.createPost(postType: postType, caption: caption, photoURL: photoURL)
                
                DatabaseManager.shared.insertNewPost(post: self.post) { isSuccessfull in
                    if isSuccessfull {
                        completion(true)
                    }
                }
                
            case .failure(let error):
                completion(false)
                print(error)
            }
        }
    }
    
    
}
