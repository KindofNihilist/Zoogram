//
//  PostsSection.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 03.07.2023.
//

import UIKit

class PostsSection: CollectionSectionController {

    override func itemSize() -> CGSize {
        guard let superView = self.sectionHolder.superview else {
            return CGSize.zero
        }
        let numberOfCells = 3
        let availableWidth = superView.frame.width - CGFloat(numberOfCells)
        let cellWidth = availableWidth / CGFloat(numberOfCells)
        return CGSize(width: cellWidth, height: cellWidth)
    }

    override func lineSpacing() -> CGFloat {
        return 1
    }

    override func interitemSpacing() -> CGFloat {
        return 1
    }
}
