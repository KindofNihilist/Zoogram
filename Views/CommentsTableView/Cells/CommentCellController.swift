//
//  CommentTableViewCellBuilder.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 24.05.2023.
//

import UIKit.UITableView

class CommentCellController: GenericCellController<CommentTableViewCell> {

    private let viewModel: CommentViewModel

    private let delegate: CommentCellProtocol

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

    override func configureCell(_ cell: CommentTableViewCell) {
        if isAPostCaption {
            cell.configurePostCaption(with: viewModel)
        } else {
            cell.configure(with: viewModel)
        }
        cell.delegate = self.delegate
    }

    func isCellEditable() -> Bool {
        return self.canEdit
    }
}
