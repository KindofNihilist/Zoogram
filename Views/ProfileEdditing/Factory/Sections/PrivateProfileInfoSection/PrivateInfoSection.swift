//
//  PrivateInfoSection.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 10.01.2024.
//

import UIKit.UITableView

class PrivateInfoSection: TableSectionController {

    override func header() -> UIView? {
        guard let view = sectionHolder.dequeueReusableHeaderFooterView(withIdentifier: ProfileEdditingSectionHeader.identifier) as? ProfileEdditingSectionHeader else {
            return nil
        }
        view.title.text = String(localized: "Private Info")
        return view
    }

    override func headerHeight() -> CGFloat {
        return 80
    }

    override func rowHeight() -> CGFloat {
        return UITableView.automaticDimension
    }

    override func registerSupplementaryViews() {
        sectionHolder.register(ProfileEdditingSectionHeader.self, forHeaderFooterViewReuseIdentifier: ProfileEdditingSectionHeader.identifier)
    }
}
