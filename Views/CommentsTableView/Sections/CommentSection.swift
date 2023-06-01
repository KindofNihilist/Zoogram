//
//  CommentSection.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 26.05.2023.
//

import UIKit

class CommentSection: TableViewSectionBuilder {

    var sectionIndex: SectionIndex

    weak var delegate: SectionManager?

    var builders: [TableViewCellBuilder]

    init(builders: [TableViewCellBuilder], delegate: SectionManager) {
        self.builders = builders
        self.delegate = delegate
        self.sectionIndex = delegate.getSectionIndex()
    }

    func numberOfRows() -> Int {
        return builders.count
    }

    func cell(at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        return builders[indexPath.row].cellAt(indexPath: indexPath, for: tableView)
    }

    func canEditCell(at indexPath: IndexPath) -> Bool {
        return builders[indexPath.row].canEdit
    }

    func editingStyleForCell(at indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return builders[indexPath.row].editingStyle
    }

    func removeCell(at indexPath: IndexPath, in tableView: UITableView, with animation: UITableView.RowAnimation) {
        removeBuilder(at: indexPath)
        tableView.deleteRows(at: [indexPath], with: animation)
    }

    func insertCell(for builder: TableViewCellBuilder, at indexPath: IndexPath, in tableView: UITableView, with animation: UITableView.RowAnimation) {
        appendBuilder(builder)
        tableView.beginUpdates()
        tableView.insertRows(at: [indexPath], with: animation)
        tableView.endUpdates()
    }

}
