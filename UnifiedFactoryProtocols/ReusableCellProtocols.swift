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

public protocol SupplementaryView: AnyObject {
    associatedtype ViewHolder: ReusableCellHolder
}

extension UIView: SupplementaryView {
    public typealias ViewHolder = UITableView
}

extension UICollectionReusableView: SupplementaryView {
    public typealias ViewHolder = UICollectionView
}


public protocol ReusableCellHolder: AnyObject {
    associatedtype CellType: ReusableCell
    associatedtype SupplementaryViewType: SupplementaryView
    func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String)
    func dequeueReusableCell(withCellIdentifier identifier: String, for indexPath: IndexPath) -> CellType
    func cell(at indexPath: IndexPath) -> CellType?
    func insertCell(at indexPath: IndexPath)
    func removeCell(at indexPath: IndexPath)
}

extension UITableViewCell: ReusableCell {
    public typealias CellHolder = UITableView
}

extension UICollectionViewCell: ReusableCell {
    public typealias CellHolder = UICollectionView
}

extension UITableView: ReusableCellHolder {

    public typealias SupplementaryViewType = UIView

    
    public func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        register(cellClass, forCellReuseIdentifier: identifier)
    }

    public func dequeueReusableCell(withCellIdentifier identifier: String, for indexPath: IndexPath) -> UITableViewCell {
        return dequeueReusableCell(withIdentifier: identifier, for: indexPath)
    }

    public func cell(at indexPath: IndexPath) -> UITableViewCell? {
        return cellForRow(at: indexPath)
    }

    public func insertCell(at indexPath: IndexPath) {
        insertRows(at: [indexPath], with: .automatic)
    }

    public func removeCell(at indexPath: IndexPath) {
        deleteRows(at: [indexPath], with: .automatic)
    }

}

extension UICollectionView: ReusableCellHolder {
    
    public typealias SupplementaryViewType = UICollectionReusableView


    public func register(_ cellClass: AnyClass?, forCellWithIdentifier identifier: String) {
        register(cellClass, forCellWithReuseIdentifier: identifier)
    }

    public func dequeueReusableCell(withCellIdentifier identifier: String, for indexPath: IndexPath) -> UICollectionViewCell {
        return dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
    }

    public func cell(at indexPath: IndexPath) -> UICollectionViewCell? {
        cellForItem(at: indexPath)
    }

    public func insertCell(at indexPath: IndexPath) {
        performBatchUpdates {
            insertItems(at: [indexPath])
        }
    }

    public func removeCell(at indexPath: IndexPath) {
        performBatchUpdates {
            deleteItems(at: [indexPath])
        }
    }
}
