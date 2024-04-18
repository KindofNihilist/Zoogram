//
//  TableViewCellBuilderProtocol.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 24.05.2023.
//

import Foundation

open class CellController<T: ReusableCellHolder> {

    private weak var reusableCellHolder: T?

    var relatedSection: SectionController<T>?

    var cell: T.CellType?

    var allowsEditing: Bool = false

    var didSelectAction: ((IndexPath) -> Void)?

    public var indexPath: IndexPath?

    var cellClass: AnyClass {
        fatalError("must be overriden")
    }

    public var identifier: String {
        return String(describing: cellClass)
    }

    public func registerCell(in reusableCellHolder: T) {
        reusableCellHolder.register(cellClass, forCellWithReuseIdentifier: identifier)
    }

    public final func cellFromReusableCellHolder(_ reusableCellHolder: T, for indexPath: IndexPath) -> T.CellType {
        let cell = reusableCellHolder.dequeueReusableCell(withCellIdentifier: identifier, for: indexPath)
        configureCell(cell, at: indexPath)
        self.indexPath = indexPath
        self.reusableCellHolder = reusableCellHolder
        self.cell = cell
        return cell
    }

    open func configureCell(_ cell: T.CellType, at indexPath: IndexPath? = nil) {
        // Must be overriden by children to configure a cell
    }

    open func willDisplayCell(_ cell: T.CellType) {
        // By default do nothing.
    }

    open func didEndDisplayingCell(_ cell: T.CellType) {
        // By default do nothing.
    }

    open func didSelectCell(at indexPath: IndexPath) {
    }
}
