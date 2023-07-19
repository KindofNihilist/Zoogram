//
//  TableViewCellBuilderProtocol.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 24.05.2023.
//

import UIKit.UITableView

class CellController<T: ReusableCellHolder> {

    var allowsEditing: Bool = false

    open class var cellClass: AnyClass {
        fatalError("must be overriden")
    }

    public static var identifier: String {
        return String(describing: cellClass)
    }

    public static func registerCell(in reusableCellHolder: T) {
        reusableCellHolder.register(cellClass, forCellWithReuseIdentifier: identifier)
    }

    public final func cellFromReusableCellHolder(_ reusableCellHolder: T, for indexPath: IndexPath) -> T.CellType {
        let cell = reusableCellHolder.dequeueReusableCell(withReuseIdentifier: type(of: self).identifier, for: indexPath)
        configureCell(cell)
        return cell
    }

    open func configureCell(_ cell: T.CellType) {
        //Must be overriden by children to configure a cell
    }
}
