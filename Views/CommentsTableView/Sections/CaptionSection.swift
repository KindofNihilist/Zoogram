//
//  CaptionSection.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 26.05.2023.
//

import UIKit

class CaptionSection: TableViewSectionBuilder {

    var sectionIndex: SectionIndex

    weak var delegate: SectionManager?

    var builders: [TableViewCellBuilder]

    init(builders: [TableViewCellBuilder], delegate: SectionManager) {
        self.builders = builders
        self.delegate = delegate
        self.sectionIndex = delegate.getSectionIndex()
    }

    func numberOfRows() -> Int {
        return builders.count
    }

    func cell(at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        return builders[indexPath.row].cellAt(indexPath: indexPath, for: tableView)
    }

    func footerView() -> UIView? {
        let separatorView = UIView()
        separatorView.backgroundColor = ColorScheme.separatorColor
        return separatorView
    }

    func heightForFooter() -> CGFloat {
        return 2
    }
}
