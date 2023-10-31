//
//  CollectionPostController.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 19.07.2023.
//

import UIKit

class CollectionPostController: GenericCellController<PhotoCollectionViewCell> {

    private let postPhoto: UIImage

    private var action: ((IndexPath) -> Void)?

    init(post: PostViewModel, action: @escaping (IndexPath) -> Void) {
        self.action = action
        self.postPhoto = post.postImage
//        print("Creating post controller for \(post.postID)")
    }

    override func configureCell(_ cell: PhotoCollectionViewCell) {
        cell.configure(with: postPhoto)
    }

    override func didSelectCell(at indexPath: IndexPath) {
        action?(indexPath)
    }

}
