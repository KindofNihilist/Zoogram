//
//  ReusableCellProtocols.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 30.05.2023.
//

import Foundation
import UIKit

public protocol ReusableCell: AnyObject {
    associatedtype CellHolder: ReusableCellHolder
}

public protocol ReusableCellHolder: AnyObject {
    associatedtype CellType: ReusableCell
    func register(_ nib: UINib?, forCellWithReuseIdentifier identifier: String)
    func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String)
    func dequeueReusableCell(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> CellType
    func cellForItem(at indexPath: IndexPath) -> CellType?
}

extension UITableViewCell: ReusableCell {
    public typealias CellHolder = UITableView
}

extension UICollectionViewCell: ReusableCell {
    public typealias CellHolder = UICollectionView
}

extension UITableView: ReusableCellHolder {
    public func register(_ nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        register(nib, forCellReuseIdentifier: identifier)
    }

    public func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        register(cellClass, forCellReuseIdentifier: identifier)
    }

    public func dequeueReusableCell(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> UITableViewCell {
        return dequeueReusableCell(withIdentifier: identifier, for: indexPath)
    }

    public func cellForItem(at indexPath: IndexPath) -> UITableViewCell? {
        return cellForRow(at: indexPath)
    }

}

extension UICollectionView: ReusableCellHolder {

}
