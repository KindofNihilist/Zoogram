//
//  CommentSection.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 26.05.2023.
//

import UIKit

class CommentSection: TableSectionController {

    override func canEditCell(at indexPath: IndexPath) -> Bool {
        guard let cellController = cellControllers[indexPath.row] as? CommentCellController else {
            return false
        }
        return cellController.allowsEditing
    }

    override func editingStyleForCell(at indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let cellController = cellControllers[indexPath.row] as? CommentCellController
        return cellController?.editingStyle ?? .none
    }

}
