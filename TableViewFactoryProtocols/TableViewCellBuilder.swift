//
//  TableViewCellBuilderProtocol.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 24.05.2023.
//

import UIKit.UITableView

protocol TableViewCellBuilder {
    func cellAt(indexPath: IndexPath, for tableView: UITableView) -> UITableViewCell
    var canEdit: Bool { get set }
    var editingStyle: UITableViewCell.EditingStyle { get set }
}
