//
//  CommentTableViewCellBuilder.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 24.05.2023.
//

import UIKit.UITableView

class CommentCellController: GenericCellController<CommentTableViewCell> {

     var comment: PostComment

    private let delegate: CommentCellProtocol

    var editingStyle: UITableViewCell.EditingStyle = .none

    private let isAPostCaption: Bool

    init(comment: PostComment, isAPostCaption: Bool = false, delegate: CommentCellProtocol) {
        self.comment = comment
        self.delegate = delegate
        self.isAPostCaption = isAPostCaption
        super.init()
        self.allowsEditing = comment.canBeEdited
        if self.allowsEditing {
            editingStyle = .delete
        }
    }

    override func configureCell(_ cell: CommentTableViewCell, at indexPath: IndexPath? = nil) {
        if isAPostCaption {
            cell.configurePostCaption(with: comment)
        } else {
            cell.configure(with: comment)
        }
        cell.delegate = self.delegate
    }

    func isCellEditable() -> Bool {
        return self.allowsEditing
    }

    func markAsSeen() {
        self.comment.shouldBeMarkedUnseen = false
        cell()?.markAsSeen()
    }

    func focus() {
        cell()?.focus()
    }

    func markAsPublished() {
        self.comment.hasBeenPosted = true
        cell()?.markAsPublished()
    }
}
