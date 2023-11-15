//
//  CommentTableViewCellBuilder.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 24.05.2023.
//

import UIKit.UITableView

class CommentCellController: GenericCellController<CommentTableViewCell> {

     let viewModel: CommentViewModel

    private let delegate: CommentCellProtocol

    var editingStyle: UITableViewCell.EditingStyle = .none

    private let isAPostCaption: Bool

    init(viewModel: CommentViewModel, isAPostCaption: Bool = false, delegate: CommentCellProtocol) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.isAPostCaption = isAPostCaption
        super.init()
        self.allowsEditing = viewModel.canBeEdited
        if self.allowsEditing {
            editingStyle = .delete
        }
    }

//    override func configureCell(_ cell: DefaultTableViewCell, at indexPath: IndexPath? = nil) {
//        var config = cell.defaultContentConfiguration()
//        config.text = viewModel.commentText
//        cell.contentConfiguration = config
//    }

    override func configureCell(_ cell: CommentTableViewCell, at indexPath: IndexPath? = nil) {
        if isAPostCaption {
            cell.configurePostCaption(with: viewModel)
        } else {
            print("Comment: \(viewModel.commentText) on indexPath: \(indexPath)")
            cell.configure(with: viewModel)
        }
        cell.delegate = self.delegate
    }
//    override func configureCell(_ cell: CommentTableViewCell) {
//        if isAPostCaption {
//            cell.configurePostCaption(with: viewModel)
//        } else {
//            cell.configure(with: viewModel)
//        }
//        cell.delegate = self.delegate
//    }

    func isCellEditable() -> Bool {
        return self.allowsEditing
    }
}
