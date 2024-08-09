//
//  DiscoverCollectionViewFactory.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.04.2024.
//

import Foundation
import UIKit.UICollectionView

class DiscoverCollectionViewFactory: CollectionFactoryWithPaginationIndicator {

    func buildSections(for posts: [PostViewModel]) {
        self.sections.removeAll()
        let cellControllers = posts.map { postModel in
            return CollectionPostController(post: postModel) { indexPath in
                self.cellAction?(indexPath)
            }
        }

        mainContentSection = PostsSection(sectionHolder: collectionView, cellControllers: cellControllers, sectionIndex: 0)
        sections.append(mainContentSection)

        paginationIndicatorSection = PaginationIndicatorSection(sectionHolder: collectionView, cellControllers: [], sectionIndex: 1)
        sections.append(paginationIndicatorSection)
    }

    override func createCellControllers(for items: [Any]) -> [CollectionCellController]? {
        guard let postViewModels = items as? [PostViewModel] else { return nil }

        return postViewModels.map { postModel in
            CollectionPostController(post: postModel, didSelectAction: cellAction)
        }
    }
}
