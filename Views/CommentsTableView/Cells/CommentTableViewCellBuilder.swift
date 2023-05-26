//
//  CommentTableViewCellBuilder.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 24.05.2023.
//

import UIKit.UITableView

class CommentTableViewCellBuilder: TableViewCellBuilder {

    private let viewModel: CommentViewModel

    private let delegate: CommentCellProtocol

    private let identifier = CommentTableViewCell.identifier

    var editingStyle: UITableViewCell.EditingStyle = .none

    var canEdit: Bool = false

    private let isAPostCaption: Bool

    init(viewModel: CommentViewModel, isAPostCaption: Bool = false, delegate: CommentCellProtocol) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.isAPostCaption = isAPostCaption
        self.canEdit = viewModel.canBeEdited
        if self.canEdit {
            editingStyle = .delete
        }
    }

    func cellAt(indexPath: IndexPath, for tableView: UITableView) -> UITableViewCell {
        let cell: CommentTableViewCell = tableView.dequeue(withIdentifier: identifier, for: indexPath)

        if isAPostCaption {
            cell.configurePostCaption(with: viewModel)
        } else {
            cell.configure(with: viewModel)
        }
        cell.configure(with: viewModel)
        cell.delegate = self.delegate

        return cell
    }

    func isCellEditable() -> Bool {
        return self.canEdit
    }
}
