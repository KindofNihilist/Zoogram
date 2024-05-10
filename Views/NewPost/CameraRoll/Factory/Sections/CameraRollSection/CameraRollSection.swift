//
//  CameraRollSection.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 15.11.2023.
//

import UIKit.UICollectionView

class CameraRollSection: CollectionSectionController {

    weak var delegate: CameraRollHeaderDelegate?

    override func header(at indexPath: IndexPath) -> UICollectionReusableView {
        let header = sectionHolder.dequeueReusableView(
            withIdentifier: CameraRollHeaderView.identifier,
            ofKind: UICollectionView.elementKindSectionHeader,
            for: indexPath) as! CameraRollHeaderView
        header.delegate = delegate
        return header
    }

    override func registerSupplementaryViews() {
        sectionHolder.register(
            CameraRollHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: CameraRollHeaderView.identifier)
    }

    override func itemSize() -> CGSize {
        guard let superview = sectionHolder.superview else {
            return CGSize.zero
        }

        let numberOfItems: CGFloat = 4
        let availableWidth = superview.frame.width - numberOfItems
        let cellSize = availableWidth / numberOfItems
        return CGSize(width: cellSize, height: cellSize)
    }

    override func headerHeight() -> CGSize? {
        return CGSize(width: sectionHolder.frame.width, height: 50)
    }

    override func interitemSpacing() -> CGFloat {
        return 1
    }

    override func lineSpacing() -> CGFloat {
        return 1
    }
}
