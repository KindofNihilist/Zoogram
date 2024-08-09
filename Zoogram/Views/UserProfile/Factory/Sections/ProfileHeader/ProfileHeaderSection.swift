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

    override func configureCell(_ cell: ProfileHeaderCell, at indexPath: IndexPath? = nil) {
        cell.configureWith(viewModel: userProfileViewModel)
        cell.delegate = self.delegate
    }
}

class ProfileHeaderSection: CollectionSectionController {

    private var bio: String?

    init(bio: String?, sectionHolder: UICollectionView, cellControllers: [CellController<UICollectionView>], sectionIndex: Int) {
        self.bio = bio
        super.init(sectionHolder: sectionHolder, cellControllers: cellControllers, sectionIndex: sectionIndex)
    }

    override func itemSize() -> CGSize {
        guard let superview = sectionHolder.superview
        else {
            return CGSize.zero
        }
        let width = superview.frame.width
        let headerHeight = calculateHeaderHeight(bio: self.bio, frameWidth: width)
        return CGSize(width: width, height: headerHeight)
    }

    private func calculateHeaderHeight(bio: String?, frameWidth: CGFloat) -> CGFloat {
        let bioPadding: CGFloat = 30
        let constraintRect = CGSize(width: frameWidth - bioPadding, height: .greatestFiniteMagnitude)
        let biolessHeaderHeight: CGFloat = 218 // a sum of all ProfileHeaderCell height anchors and bottom, top paddings, janky solution and ideally should be computed

        if let bio = bio {
            let font = CustomFonts.regularFont(ofSize: 15)
            let boundingBox = bio.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)

            if boundingBox.height > 0 {
                let headerHeight = boundingBox.height + biolessHeaderHeight
                return ceil(headerHeight)
            } else {
                return biolessHeaderHeight
            }
        } else {
            return biolessHeaderHeight
        }
    }
}
