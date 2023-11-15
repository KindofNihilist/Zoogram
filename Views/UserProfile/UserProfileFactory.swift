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

    private var isAlreadyShowingLoadingIndicator: Bool = false

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

        loadingIndicatorSection = PaginationIndicatorSection(sectionHolder: collectionView, cellControllers: [], sectionIndex: 2)
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
        guard self.isAlreadyShowingLoadingIndicator else {
            return
        }
        let sectionIndex = loadingIndicatorSection.sectionIndex
        loadingIndicatorSection.cellControllers.removeAll()
        collectionView.reloadSections(IndexSet(integer: sectionIndex))
        self.isAlreadyShowingLoadingIndicator = false
    }

    func showLoadingIndicator() {
        guard self.isAlreadyShowingLoadingIndicator == false else {
            return
        }
        let sectionIndex = loadingIndicatorSection.sectionIndex
        loadingIndicatorSection.cellControllers.append(LoadingIndicatorController())
        collectionView.reloadSections(IndexSet(integer: sectionIndex))
        self.isAlreadyShowingLoadingIndicator = true
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
        return PostsSection(sectionHolder: collectionView, cellControllers: cellControllers, sectionIndex: 1)
    }

}
