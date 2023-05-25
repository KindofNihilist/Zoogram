//
//  BaseSection.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 24.05.2023.
//

import UIKit

class BaseSection: TableViewSectionBuilder {

    var builders: [TableViewCellBuilder]

    init(builders: [TableViewCellBuilder]) {
        self.builders = builders
    }

    func numberOfRows() -> Int {
        return builders.count
    }

    func heightForHeader() -> CGFloat {
        return 0
    }

    func headerView() -> UIView? {
        return nil
    }

    func cell(at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        return builders[indexPath.row].cellAt(indexPath: indexPath, for: tableView)
    }

    func canEditCell(at indexPath: IndexPath) -> Bool {
        return builders[indexPath.row].canEdit
    }

    func editingStyleForCell(at indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return builders[indexPath.row].editingStyle
    }
}
