//
//  DefaultCollectionViewDataSource.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 20.07.2023.
//

import UIKit

protocol CollectionViewDataSourceDelegate: AnyObject {
    func scrollViewDidScroll(scrollView: UIScrollView)
}

protocol CollectionViewDataSource: UICollectionViewDelegate, UICollectionViewDataSource {}

class DefaultCollectionViewDataSource: NSObject, CollectionViewDataSource {

    private var sections: [CollectionSectionController]

    weak var delegate: CollectionViewDataSourceDelegate?

    init(sections: [CollectionSectionController]) {
        self.sections = sections
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].numberOfCells()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return sections[indexPath.section].cell(at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        sections[indexPath.section].cellController(at: indexPath).didSelectCell(at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return sections[indexPath.section].getSupplementaryView(of: kind, at: indexPath)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidScroll(scrollView: scrollView)
    }
}

extension DefaultCollectionViewDataSource: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return sections[section].headerHeight() ?? CGSize(width: UIView.layoutFittingCompressedSize.width, height: UIView.layoutFittingCompressedSize.height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return sections[section].footerHeight() ?? CGSize(width: UIView.layoutFittingCompressedSize.width, height: UIView.layoutFittingCompressedSize.height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return sections[indexPath.section].itemSize()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sections[section].sectionInsets()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sections[section].lineSpacing()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return sections[section].interitemSpacing()
    }
}
