//
//  TableViewSectionBuilder.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 24.05.2023.
//

import UIKit

typealias SectionIndex = Int
typealias SupplementaryViewKind = String

@MainActor class SectionController<T: ReusableCellHolder> {

    var cellControllers: [CellController<T>]
    let sectionHolder: T
    public var sectionIndex: SectionIndex

    init(sectionHolder: T, cellControllers: [CellController<T>], sectionIndex: Int) {
        self.sectionIndex = sectionIndex
        self.sectionHolder = sectionHolder
        self.cellControllers = cellControllers
        self.registerSupplementaryViews()
    }

    public final func numberOfCells() -> Int {
        return cellControllers.count
    }

    public final func cell(at indexPath: IndexPath) -> T.CellType {
        let cellController = cellControllers[indexPath.row]
        cellController.relatedSection = self
        registerCell(at: indexPath)
        let cell = cellController.cellFromReusableCellHolder(sectionHolder, for: indexPath)
        return cell
    }

    public final func cellController(at indexPath: IndexPath) -> CellController<T> {
        let cellController = cellControllers[indexPath.row]
        return cellController
    }

    final func registerCell(at indexPath: IndexPath) {
        let cell = cellControllers[indexPath.row]
        cell.registerCell(in: sectionHolder)
    }

    final func appendCellControllers(controllers: [CellController<T>]) {
        self.cellControllers.append(contentsOf: controllers)
    }

    final func appendCellController(controller: CellController<T>, at position: Int) {
        self.cellControllers.insert(controller, at: position)
    }

    final func removeCellController(at indexPath: IndexPath) {
        self.cellControllers.remove(at: indexPath.row)
    }

    public func registerSupplementaryViews() {}
}
