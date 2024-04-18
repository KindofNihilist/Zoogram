//
//  BookmarksFactory.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 09.01.2024.
//

import UIKit.UICollectionView

class BookmarksFactory {

    private let collectionView: UICollectionView

    var postCellAction: ((IndexPath) -> Void)?
    var sections = [CollectionSectionController]()
    private var postsSection: PostsSection!
    private var paginationIndicatorSection: PaginationIndicatorSection!
    private var paginationIndicatorController: PaginationIndicatorController?

    init(for collectionView: UICollectionView) {
        self.collectionView = collectionView
    }

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

    func getSections() -> [CollectionSectionController] {
        return self.sections
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
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

    func hideLoadingFooter() {
        guard paginationIndicatorController != nil else { return }
        let sectionIndex = paginationIndicatorSection.sectionIndex
        paginationIndicatorSection.cellControllers.removeAll()
        paginationIndicatorController = nil
        collectionView.reloadSections(IndexSet(integer: sectionIndex))
    }

    func showLoadingIndicator() {
        guard paginationIndicatorController == nil else {
            if let paginationCell = paginationIndicatorController?.cell as? PaginationIndicatorCell {
                paginationCell.showLoadingIndicator()
            }
            return
        }
        paginationIndicatorSection.cellControllers.removeAll()
        let sectionIndex = paginationIndicatorSection.sectionIndex
        self.paginationIndicatorController = PaginationIndicatorController()
        paginationIndicatorSection.cellControllers.append(self.paginationIndicatorController!)
        collectionView.reloadSections(IndexSet(integer: sectionIndex))
    }

    func showPaginationRetryButton(error: Error, delegate: PaginationIndicatorCellDelegate?) {
        let sectionIndex = paginationIndicatorSection.sectionIndex
        guard let paginationCell = collectionView.cellForItem(at: IndexPath(row: 0, section: sectionIndex)) as? PaginationIndicatorCell
        else { return }
        paginationCell.displayLoadingError(error, delegate: delegate)
    }
}
