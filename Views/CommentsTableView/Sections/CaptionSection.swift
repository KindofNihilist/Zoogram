//
//  CaptionSection.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 26.05.2023.
//

import UIKit

class CaptionSection: TableSectionController {

    override func footer() -> UIView? {
        let separatorView = UIView()
        separatorView.backgroundColor = ColorScheme.separatorColor
        return separatorView
    }

    override func footerHeight() -> CGFloat {
        return 1
    }

}
