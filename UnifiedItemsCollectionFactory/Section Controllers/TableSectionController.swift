//
//  TableSectionController.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 20.06.2024.
//

import UIKit

class TableSectionController: SectionController<UITableView> {
    open func canEditCell(at indexPath: IndexPath) -> Bool {
        return false
    }

    open func editingStyleForCell(at indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    public func header() -> UIView? {
        return nil
    }

    public func headerHeight() -> CGFloat {
        return 0
    }

    public func footer() -> UIView? {
        return nil
    }

    public func footerHeight() -> CGFloat {
        return 0
    }

    public func rowHeight() -> CGFloat {
        return 0
    }

    public func estimatedRowHeight() -> CGFloat? {
        return nil
    }

    final func insertCell(with cellController: TableCellController, at position: Int) {
        self.cellControllers.insert(cellController, at: position)
        sectionHolder.beginUpdates()
        let indexPath = IndexPath(row: position, section: sectionIndex)
        sectionHolder.insertRows(at: [indexPath], with: .automatic)
        sectionHolder.endUpdates()
    }

    final func removeCell(at indexPath: IndexPath) {
        self.cellControllers.remove(at: indexPath.row)
        sectionHolder.deleteRows(at: [indexPath], with: .automatic)
    }
}
