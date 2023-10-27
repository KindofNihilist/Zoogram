//
//  UserProfileFactory.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 19.07.2023.
//

import UIKit

class UserProfileFactory {

    private let collectionView: UICollectionView

    let headerDelegate: ProfileHeaderDelegate

    var postCellAction: ((IndexPath) -> Void)?

    var sections = [CollectionSectionController]()

    private var headerSection: ProfileHeaderSection!

    private var postsSection: PostsSection!

    private var loadingIndicatorSection: PaginationIndicatorSection!

    init(for collectionView: UICollectionView, headerDelegate: ProfileHeaderDelegate) {
        self.collectionView = collectionView
        self.headerDelegate = headerDelegate
    }

    func buildSections(profileViewModel: UserProfileViewModel) {
        let headerController = ProfileHeaderController(for: profileViewModel)
        headerController.delegate = headerDelegate
        headerSection = ProfileHeaderSection(userProfileViewModel: profileViewModel, sectionHolder: collectionView, cellControllers: [headerController])
        sections.append(headerSection)

        guard profileViewModel.posts.value.isEmpty != true else {
            let noPostsSection = NoPostsSection(sectionHolder: collectionView, cellControllers: [NoPostsCellController()])
            sections.append(noPostsSection)
            return
        }
        postsSection = createPostsSection(with: profileViewModel.posts.value)
        postsSection?.registerSupplementaryViews()
        sections.append(postsSection)

        loadingIndicatorSection = PaginationIndicatorSection(sectionHolder: collectionView, cellControllers: [LoadingIndicatorController()])
        sections.append(loadingIndicatorSection)
    }

    func getSections() -> [CollectionSectionController] {
        return self.sections
    }

    func refreshPostsSection(with posts: [PostViewModel]) {
        postsSection = createPostsSection(with: posts)
    }

    func updatePostsSection(with posts: [PostViewModel]) {
        let cellControllers = posts.map { postViewModel in
            CollectionPostController(post: postViewModel) { indexPath in
                self.postCellAction?(indexPath)
            }
        }
        postsSection?.appendCellControllers(controllers: cellControllers)

    }

    func updatePostsSectionFooterHeight(to height: CGFloat) {
//        self.postsSection.calculatedFooterHeight = CGSize(width: 0, height: height)
    }

    func hideLoadingFooter() {
        guard let sectionIndex = loadingIndicatorSection.sectionIndex else {
            return
        }
        loadingIndicatorSection.cellControllers.removeAll()
        collectionView.reloadSections(IndexSet(integer: sectionIndex))
    }

    func showLoadingIndicator() {
        guard let sectionIndex = loadingIndicatorSection.sectionIndex else {
            return
        }

        loadingIndicatorSection.cellControllers.append(LoadingIndicatorController())
        collectionView.reloadSections(IndexSet(integer: sectionIndex))
    }

    func setShouldDisplayLoadingFooter(_ status: Bool) {
//        self.postsSection.displaysLoadingFooter = status
    }

    private func createPostsSection(with posts: [PostViewModel]) -> PostsSection {
        let cellControllers = posts.map { postViewModel in
            CollectionPostController(post: postViewModel) { indexPath in
                self.postCellAction?(indexPath)
            }
        }
        return PostsSection(sectionHolder: collectionView, cellControllers: cellControllers)
    }

}
