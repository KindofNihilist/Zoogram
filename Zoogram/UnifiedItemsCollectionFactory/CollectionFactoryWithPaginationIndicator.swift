//
//  CollectionFactoryWithPaginationIndicator.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.04.2024.
//

import Foundation

import UIKit.UICollectionView

@MainActor class CollectionFactoryWithPaginationIndicator {

    weak var delegate: PaginationIndicatorCellDelegate?

    let collectionView: UICollectionView
    var sections = [CollectionSectionController]()
    var mainContentSection: CollectionSectionController!
    var cellAction: ((IndexPath) -> Void)?

    var paginationIndicatorSection: PaginationIndicatorSection!
    var paginationIndicatorController: PaginationIndicatorController?

    init(for collectionView: UICollectionView) {
        self.collectionView = collectionView
    }

    func buildSections(profileViewModel: UserProfileViewModel) {}

    func getSections() -> [CollectionSectionController] {
        return self.sections
    }

    func createCellControllers(for items: [Any]) -> [CollectionCellController]? {
        fatalError("Should be overriden")
    }

    func updatePostsSection(with items: [Any], completion: @escaping () -> Void) {
        guard let cellControllers = createCellControllers(for: items) else { return }
        let postsCountBeforeUpdate = mainContentSection.numberOfCells()
        mainContentSection.appendCellControllers(controllers: cellControllers)

        let postsCountAfterUpdate = self.mainContentSection.numberOfCells()
        let indexPaths = (postsCountBeforeUpdate ..< postsCountAfterUpdate).map {
            IndexPath(row: $0, section: mainContentSection.sectionIndex)
        }
        self.collectionView.performBatchUpdates {
            self.collectionView.insertItems(at: indexPaths)
        } completion: { _ in
            completion()
        }
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

    func showPaginationRetryButton(error: Error) {
        let sectionIndex = paginationIndicatorSection.sectionIndex
        let indexPath = IndexPath(row: 0, section: sectionIndex)
        guard let paginationCell = collectionView.cellForItem(at: indexPath) as? PaginationIndicatorCell
        else { return }
        paginationCell.delegate = self.delegate
        paginationCell.displayLoadingError(error)
    }

    private func createPostsSection(with posts: [PostViewModel]) -> PostsSection {
        let cellControllers = posts.map { postViewModel in
            CollectionPostController(post: postViewModel) { indexPath in
                self.cellAction?(indexPath)
            }
        }
        return PostsSection(sectionHolder: collectionView, cellControllers: cellControllers, sectionIndex: 1)
    }
}
