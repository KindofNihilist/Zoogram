//
//  PreviewSection.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 16.11.2023.
//

import UIKit.UICollectionView

class PreviewSection: CollectionSectionController {

    var previewImage: UIImage?

    override func registerSupplementaryViews() {
        sectionHolder.register(
            PreviewHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: PreviewHeaderView.identifier)
    }

    override func header(at indexPath: IndexPath) -> UICollectionReusableView {
        let header = sectionHolder.dequeueReusableView(
            withIdentifier: PreviewHeaderView.identifier,
            ofKind: UICollectionView.elementKindSectionHeader,
            for: indexPath) as! PreviewHeaderView
        header.updatePreview(with: previewImage)
        return header
    }

    override func headerHeight() -> CGSize? {
        return CGSize(width: sectionHolder.frame.width, height: sectionHolder.frame.width)
    }
}
