//
//  CollectionSectionController.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 20.06.2024.
//

import UIKit

class CollectionSectionController: SectionController<UICollectionView> {

    override init(sectionHolder: UICollectionView, cellControllers: [CellController<UICollectionView>], sectionIndex: Int) {
        super.init(sectionHolder: sectionHolder, cellControllers: cellControllers, sectionIndex: sectionIndex)
    }

    public func itemSize() -> CGSize {
        return CGSize.zero
    }

    public func sectionInsets() -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    public func lineSpacing() -> CGFloat {
        return 0
    }

    public func interitemSpacing() -> CGFloat {
        return 0
    }

    public func header(at indexPath: IndexPath) -> UICollectionReusableView {
        return UICollectionReusableView()
    }

    public func footer(at indexPath: IndexPath) -> UICollectionReusableView {
        return UICollectionReusableView()
    }

    public func headerHeight() -> CGSize? {
        return nil
    }

    public func footerHeight() -> CGSize? {
        return nil
    }

    func getSupplementaryView(of kind: SupplementaryViewKind, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            return header(at: indexPath)
        } else if kind == UICollectionView.elementKindSectionFooter {
            return footer(at: indexPath)
        } else {
            return UICollectionReusableView()
        }
    }

    func getHeader() -> UICollectionReusableView? {
        let supplementaryView = sectionHolder.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(row: 0, section: sectionIndex))
        return supplementaryView
    }

    func getFooter() -> UICollectionReusableView? {
        let supplementaryView = sectionHolder.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: IndexPath(row: 0, section: sectionIndex))
        return supplementaryView
    }

    func calculateSupplementaryViewHeight(for view: UICollectionReusableView) -> CGSize {
        let headerViewSize = CGSize(width: sectionHolder.frame.width, height: UIView.layoutFittingCompressedSize.height)
        return view.systemLayoutSizeFitting(headerViewSize,
                                            withHorizontalFittingPriority: .required,
                                            verticalFittingPriority: .fittingSizeLevel)
    }
}
