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

    init(post: PostViewModel, didSelectAction: ((IndexPath) -> Void)?) {
        self.action = didSelectAction
        self.postPhoto = post.postImage
    }

    override func configureCell(_ cell: PhotoCollectionViewCell, at indexPath: IndexPath? = nil) {
        cell.configure(with: postPhoto)
    }

    override func didSelectCell(at indexPath: IndexPath) {
        action?(indexPath)
    }

}
