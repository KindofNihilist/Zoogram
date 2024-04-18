//
//  NewPostViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 14.10.2022.
//

import UIKit

class NewPostViewModel {

    var post: UserPost

    init(photo: UIImage) {
        self.post = UserPost.createNewPostModel()
        self.post.image = photo
    }

    func prepareForPosting(completion: @escaping (UserPost) -> Void) {
        guard let image = post.image else { return }
        post.caption = post.caption?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        completion(self.post)
    }
}
