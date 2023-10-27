//
//  GenericCellController.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 08.06.2023.
//

import UIKit

typealias TableCellController = CellController<UITableView>
typealias CollectionCellController = CellController<UICollectionView>

open class GenericCellController<T: ReusableCell>: CellController<T.CellHolder> {

    public final override var cellClass: AnyClass {
        return T.self
    }

    public final override func configureCell(_ cell: T.CellHolder.CellType) {
        let cell = cell as! T
        configureCell(cell)
    }

    public final override func willDisplayCell(_ cell: T.CellHolder.CellType) {
        let cell = cell as! T
        willDisplayCell(cell)
    }

    public final override func didEndDisplayingCell(_ cell: T.CellHolder.CellType) {
        let cell = cell as! T
        didEndDisplayingCell(cell)
    }

    open func configureCell(_ cell: T) {
        // Overrides by subclass
    }

    open func willDisplayCell(_ cell: T) {
        // Overrides by subclass
    }

    open func didEndDisplayingCell(_ cell: T) {
        // Overrides by subclass
    }
}
