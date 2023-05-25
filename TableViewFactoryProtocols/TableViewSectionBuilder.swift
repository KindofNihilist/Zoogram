//
//  TableViewSectionBuilder.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 24.05.2023.
//

import UIKit.UITableView

protocol TableViewSectionBuilder {
    var builders: [TableViewCellBuilder] { get set }

    func numberOfRows() -> Int
    func heightForHeader() -> CGFloat
    func headerView() -> UIView?
    func cell(at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell
    func canEditCell(at indexPath: IndexPath) -> Bool
    func editingStyleForCell(at indexPath: IndexPath) -> UITableViewCell.EditingStyle
 }
