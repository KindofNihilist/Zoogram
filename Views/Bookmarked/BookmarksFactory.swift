//
//  BookmarksFactory.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 09.01.2024.
//

import UIKit.UICollectionView

@MainActor class BookmarksFactory: CollectionFactoryWithPaginationIndicator {

    var postCellAction: ((IndexPath) -> Void)?
    private var postsSection: PostsSection!

    func buildSections(for bookmarks: [Bookmark]) {
        self.sections.removeAll()

        guard bookmarks.isEmpty != true else {
            let noPostsSection = NoPostsSection(sectionHolder: collectionView, cellControllers: [NoPostsCellController()], sectionIndex: 0)
            sections.append(noPostsSection)
            return
        }

        let postsCellControllers = createPostCellControllers(for: bookmarks)
        postsSection = PostsSection(sectionHolder: collectionView, cellControllers: postsCellControllers, sectionIndex: 0)
        sections.append(postsSection)

        paginationIndicatorSection = PaginationIndicatorSection(sectionHolder: collectionView, cellControllers: [], sectionIndex: 1)
        sections.append(paginationIndicatorSection)
    }

    func refreshPostsSection(with bookmarks: [Bookmark]) {
        let cellControllers = createPostCellControllers(for: bookmarks)
        postsSection.cellControllers = cellControllers
        collectionView.reloadSections(IndexSet(integer: 0))
    }

    func updatePostsSection(with bookmarks: [Bookmark], completion: @escaping () -> Void) {
        let postsCountBeforeUpdate = postsSection.numberOfCells()
        let cellControllers = createPostCellControllers(for: bookmarks)
        postsSection?.appendCellControllers(controllers: cellControllers)
        let postsCountAfterUpdate = self.postsSection.numberOfCells()
        let indexPaths = (postsCountBeforeUpdate ..< postsCountAfterUpdate).map {
            IndexPath(row: $0, section: 0)
        }
        self.collectionView.performBatchUpdates {
            self.collectionView.insertItems(at: indexPaths)
        } completion: { _ in
            completion()
        }
    }

    private func createPostCellControllers(for bookmarks: [Bookmark]) -> [CellController<UICollectionView>] {
        let bookmarkedPosts = bookmarks.compactMap { $0.associatedPost }
        let cellControllers = bookmarkedPosts.map { postViewModel in
            CollectionPostController(post: postViewModel) { indexPath in
                self.postCellAction?(indexPath)
            }
        }
        return cellControllers
    }
}
