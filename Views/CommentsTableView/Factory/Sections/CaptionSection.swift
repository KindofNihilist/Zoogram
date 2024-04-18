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
        separatorView.backgroundColor = Colors.detailGray
        return separatorView
    }

    override func footerHeight() -> CGFloat {
        return 0.5
    }

}
