//
//  CollectionViewCustomLayout.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 08.02.2022.
//

import UIKit

class CollectionViewCustomLayout: UICollectionViewFlowLayout {
    let cellsPerRow: Int

    init(cellsPerRow: Int, minimumInteritemSpacing: CGFloat = 0, minimumLineSpacing: CGFloat = 0, sectionInset: UIEdgeInsets = .zero) {
            self.cellsPerRow = cellsPerRow
            super.init()

            self.minimumInteritemSpacing = minimumInteritemSpacing
            self.minimumLineSpacing = minimumLineSpacing
            self.sectionInset = sectionInset
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func prepare() {
            super.prepare()

            guard let safeAreaInsets = collectionView?.safeAreaInsets,
                  let collectionViewWidth = collectionView?.bounds.size.width
            else { return }
            let cellsPerRow = CGFloat(cellsPerRow)
            let safeAreaInsetsCombined = safeAreaInsets.left + safeAreaInsets.right
            let sectionInsets = sectionInset.left + sectionInset.right
            let marginsAndInsets = sectionInsets + safeAreaInsetsCombined + minimumInteritemSpacing * (cellsPerRow - 1)
            let itemWidth = ((collectionViewWidth - marginsAndInsets) / (cellsPerRow - 1)).rounded(.down)
            itemSize = CGSize(width: itemWidth, height: itemWidth)
        }

        override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
            let context = super.invalidationContext(forBoundsChange: newBounds) as? UICollectionViewFlowLayoutInvalidationContext
            context?.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
            return context ?? UICollectionViewLayoutInvalidationContext()
        }
}
