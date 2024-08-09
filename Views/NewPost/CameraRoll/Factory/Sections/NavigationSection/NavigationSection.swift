//
//  NavigationSection.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 17.11.2023.
//

import UIKit.UICollectionView

class NavigationSection: CollectionSectionController {

    var header: NavigationReusableView?

    var leftButtonAction: (() -> Void)?
    var rightButtonAction: (() -> Void)?

    override func header(at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = sectionHolder.dequeueReusableView(
            withIdentifier: NavigationReusableView.identifier,
            ofKind: UICollectionView.elementKindSectionHeader,
            for: indexPath) as? NavigationReusableView
        else { fatalError("Wrong view passed") }
        header.navigationView.backgroundColor = .black
        header.navigationView.leftButton.setImage(withSystemName: "xmark")
        header.navigationView.title = String(localized: "New Post")
        header.navigationView.rightButtonTitle = String(localized: "Next")
        header.navigationView.leftButtonAction = leftButtonAction
        header.navigationView.rightButtonAction = rightButtonAction
        header.navigationView.leftButton.tintColor = .white
        header.navigationView.titleLabel.textColor = .white
        header.navigationView.rightButton.tintColor = .systemBlue
        self.header = header
        return header
    }

    override func headerHeight() -> CGSize? {
        return CGSize(width: sectionHolder.frame.width, height: 50)
    }

    override func registerSupplementaryViews() {
        sectionHolder.register(
            NavigationReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: NavigationReusableView.identifier)
    }
}
