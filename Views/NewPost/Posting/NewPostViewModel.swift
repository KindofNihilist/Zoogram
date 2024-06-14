//
//  NewPostViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 14.10.2022.
//

import UIKit

@MainActor
class NewPostViewModel {

    var post: UserPost

    init(photo: UIImage) {
        self.post = UserPost.createNewPostModel()
        self.post.image = photo
    }

    func prepareForPosting(completion: @escaping (UserPost) -> Void) {
        guard post.image != nil else { return }
        post.caption = post.caption?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        completion(self.post)
    }
}
