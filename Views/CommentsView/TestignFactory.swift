//
//  TestignFactory.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 03.11.2023.
//

import UIKit

class TestingFactory {

    private let tableView: UITableView

    var sections = [TableSectionController]()

    var commentsSection: CommentSection!

    private let delegate: CommentsTableViewActionsProtocol

    init(tableView: UITableView, delegate: CommentsTableViewActionsProtocol) {
        self.tableView = tableView
        self.delegate = delegate
    }

    func buildSections(with comments: [CommentViewModel]) {
        let commentsControllers = comments.map { commentViewModel in
            CommentCellController(viewModel: commentViewModel, delegate: self.delegate)
        }

        commentsSection = CommentSection(sectionHolder: self.tableView, cellControllers: commentsControllers, sectionIndex: 0)
        self.sections.append(commentsSection)
    }

    func insertComment(with comment: CommentViewModel, completion: @escaping () -> Void) {
        let cellController = CommentCellController(viewModel: comment, delegate: self.delegate)
        print("Inserting new comment: \(comment.commentText)")
//        commentsSection.insertCell(with: cellController, at: 0)
        commentsSection.appendCellControllers(controllers: [cellController])
        completion()
    }
}
