//
//  PostsSection.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 03.07.2023.
//

import UIKit

class PaginationIndicatorSection: CollectionSectionController {

    override func itemSize() -> CGSize {
        guard let superView = self.sectionHolder.superview else {
            return CGSize.zero
        }
        let numberOfCells: CGFloat = 3
        let availableWidth = superView.frame.width - numberOfCells
        let cellHeight = availableWidth / numberOfCells
        let cellWidth = superView.frame.width
        return CGSize(width: cellWidth, height: cellHeight)
    }
}
