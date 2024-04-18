//
//  NavigationSection.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 17.11.2023.
//

import UIKit.UICollectionView

class NavigationSection: CollectionSectionController {

    weak var delegate: NavigationHeaderActionsDelegate?

    var header: NavigationHeaderView?

    override func header(at indexPath: IndexPath) -> UICollectionReusableView {
        let header = sectionHolder.dequeueReusableView(
            withIdentifier: NavigationHeaderView.identifier,
            ofKind: UICollectionView.elementKindSectionHeader,
            for: indexPath) as! NavigationHeaderView
        header.delegate = delegate
        self.header = header
        return header
    }

    override func headerHeight() -> CGSize? {
        return CGSize(width: sectionHolder.frame.width, height: 50)
    }

    override func registerSupplementaryViews() {
        sectionHolder.register(
            NavigationHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: NavigationHeaderView.identifier)
    }
}
