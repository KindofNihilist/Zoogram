//
//  UserProfileFactory.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 19.07.2023.
//

import UIKit.UICollectionView

class UserProfileFactory {

    private let collectionView: UICollectionView

    let headerDelegate: ProfileHeaderDelegate
    var postCellAction: ((IndexPath) -> Void)?
    private var sections = [CollectionSectionController]()
    private var headerSection: ProfileHeaderSection!
    private var postsSection: PostsSection!
    private var paginationIndicatorSection: PaginationIndicatorSection!
    private var paginationIndicatorController: PaginationIndicatorController?

    init(for collectionView: UICollectionView, headerDelegate: ProfileHeaderDelegate) {
        self.collectionView = collectionView
        self.headerDelegate = headerDelegate
    }

    func buildSections(profileViewModel: UserProfileViewModel) {
        self.sections.removeAll()
        let headerController = ProfileHeaderController(for: profileViewModel)
        headerController.delegate = headerDelegate
        headerSection = ProfileHeaderSection(userProfileViewModel: profileViewModel, sectionHolder: collectionView, cellControllers: [headerController], sectionIndex: 0)
        sections.append(headerSection)

        guard profileViewModel.posts.value.isEmpty != true else {
            let noPostsSection = NoPostsSection(sectionHolder: collectionView, cellControllers: [NoPostsCellController()], sectionIndex: 1)
            sections.append(noPostsSection)
            return
        }
        postsSection = createPostsSection(with: profileViewModel.posts.value)
        sections.append(postsSection)

        paginationIndicatorSection = PaginationIndicatorSection(sectionHolder: collectionView, cellControllers: [], sectionIndex: 2)
        sections.append(paginationIndicatorSection)
    }

    func refreshProfileHeader(with viewModel: UserProfileViewModel) {
        let headerController = ProfileHeaderController(for: viewModel)
        headerController.delegate = headerDelegate
        self.headerSection?.cellControllers = [headerController]
        self.collectionView.reloadSections(IndexSet(integer: headerSection.sectionIndex))
    }

    func getSections() -> [CollectionSectionController] {
        return self.sections
    }

    func refreshPostsSection(with posts: [PostViewModel]) {
        postsSection = createPostsSection(with: posts)
    }

    func updatePostsSection(with posts: [PostViewModel], completion: @escaping () -> Void) {
        let postsCountBeforeUpdate = postsSection.numberOfCells()
        let cellControllers = posts.map { postViewModel in
            CollectionPostController(post: postViewModel) { indexPath in
                self.postCellAction?(indexPath)
            }
        }
        postsSection.appendCellControllers(controllers: cellControllers)

        let postsCountAfterUpdate = self.postsSection.numberOfCells()
        let indexPaths = (postsCountBeforeUpdate ..< postsCountAfterUpdate).map {
            IndexPath(row: $0, section: 1)
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

    func showPaginationRetryButton(error: Error, delegate: PaginationIndicatorCellDelegate?) {
        let sectionIndex = paginationIndicatorSection.sectionIndex
        guard let paginationCell = collectionView.cellForItem(at: IndexPath(row: 0, section: sectionIndex)) as? PaginationIndicatorCell
        else { return }
        paginationCell.displayLoadingError(error, delegate: delegate)
    }

    private func createPostsSection(with posts: [PostViewModel]) -> PostsSection {
        let cellControllers = posts.map { postViewModel in
            CollectionPostController(post: postViewModel) { indexPath in
                self.postCellAction?(indexPath)
            }
        }
        return PostsSection(sectionHolder: collectionView, cellControllers: cellControllers, sectionIndex: 1)
    }

}
