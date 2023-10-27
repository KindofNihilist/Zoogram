//
//  ProfileHeaderSection.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.06.2023.
//

import UIKit

class ProfileHeaderController: GenericCellController<ProfileHeaderCell> {

    private let userProfileViewModel: UserProfileViewModel

    weak var delegate: ProfileHeaderDelegate?

    init(for profileViewModel: UserProfileViewModel) {
        self.userProfileViewModel = profileViewModel
    }
    override func configureCell(_ cell: ProfileHeaderCell) {
        cell.configureWith(viewModel: userProfileViewModel)
        cell.delegate = self.delegate
    }
}

class ProfileHeaderSection: CollectionSectionController {

    private var userProfileViewModel: UserProfileViewModel

    init(userProfileViewModel: UserProfileViewModel, sectionHolder: UICollectionView, cellControllers: [CellController<UICollectionView>]) {
        self.userProfileViewModel = userProfileViewModel
        super.init(sectionHolder: sectionHolder, cellControllers: cellControllers)
    }
    override func itemSize() -> CGSize {
        guard let superview = sectionHolder.superview else {
        return CGSize.zero
        }
        return CGSize(width: superview.frame.width, height: 240)
//        let profileView = ProfileHeaderCell()
//        profileView.configureWith(viewModel: userProfileViewModel)
//        let calculatedSize = profileView.sizeThatFits(CGSize(width: superview.frame.width, height: .greatestFiniteMagnitude))
//        return CGSize(width: superview.frame.width, height: calculatedSize.height)
    }
}
