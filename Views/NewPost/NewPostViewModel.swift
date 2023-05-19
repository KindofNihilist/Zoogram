//
//  NewPostViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 14.10.2022.
//

import UIKit
import Firebase



class NewPostViewModel {

    var post: UserPost

    init() {
        self.post = UserPost.createNewPostModel()
    }

    func preparePhotoForPosting(photoToCompress: UIImage) {
        ImageCompressor.compress(image: photoToCompress, maxByte: 800000) { compressedImage in
            if let image = compressedImage {
                self.post.image = image
            }
        }
    }
}
