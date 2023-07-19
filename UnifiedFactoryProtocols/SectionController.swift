//
//  TableViewSectionBuilder.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 24.05.2023.
//

import UIKit.UITableView

typealias SectionIndex = Int

typealias TableSectionController = SectionController<UITableView>
typealias CollectionSectionController = SectionController<UICollectionView>

class SectionController<T: ReusableCellHolder> {

    var cellControllers: [CellController<T>]
    var sectionIndex: SectionIndex

    init(cellControllers: [CellController<T>]) {
        self.cellControllers = cellControllers
    }

    public final func numberOfCells() -> Int {
        return cellControllers.count
    }

    public final func cell(at indexPath: IndexPath, in cellHolder: T) -> T.CellType {
        cellControllers[indexPath.row].cellFromReusableCellHolder(_: cellHolder, for: indexPath)
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

    public func estimatedRowHeight() -> CGFloat {
        return 0
    }

    final func insertCell(with cellController: CellController<T>, at indexPath: IndexPath, in cellHolder: T) {
        self.cellControllers.insert(cellController, at: indexPath.row)
        cellHolder.insertCell(at: indexPath)
    }

    final func removeCell(at indexPath: IndexPath, in cellHolder: T) {
        self.cellControllers.remove(at: indexPath.row)
        cellHolder.removeCell(at: indexPath)
    }
}
