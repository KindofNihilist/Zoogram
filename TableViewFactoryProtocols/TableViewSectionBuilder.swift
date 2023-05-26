//
//  TableViewSectionBuilder.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 24.05.2023.
//

import UIKit.UITableView

typealias SectionIndex = Int

protocol SectionManager: AnyObject {
    func getSectionIndex() -> SectionIndex
}

protocol TableViewSectionBuilder: AnyObject {
    var builders: [TableViewCellBuilder] { get set }
    var sectionIndex: SectionIndex { get set }

    func numberOfRows() -> Int
    func cell(at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell
    func canEditCell(at indexPath: IndexPath) -> Bool
    func editingStyleForCell(at indexPath: IndexPath) -> UITableViewCell.EditingStyle
    func headerView() -> UIView?
    func heightForHeader() -> CGFloat
    func footerView() -> UIView?
    func heightForFooter() -> CGFloat
    func removeCell(at indexPath: IndexPath, in tableView: UITableView, with animation: UITableView.RowAnimation)
    func insertCell(for builder: TableViewCellBuilder, at indexPath: IndexPath, in tableView: UITableView, with animation: UITableView.RowAnimation)
    func removeBuilder(at indexPath: IndexPath)
    func appendBuilder(_ builder: TableViewCellBuilder)
 }

extension TableViewSectionBuilder {
    func headerView() -> UIView? { return nil }
    func heightForHeader() -> CGFloat { return 0}
    func footerView() -> UIView? { return nil }
    func heightForFooter() -> CGFloat { return 0 }
    func canEditCell(at indexPath: IndexPath) -> Bool { return false }
    func editingStyleForCell(at indexPath: IndexPath) -> UITableViewCell.EditingStyle { .none }
    func removeCell(at indexPath: IndexPath, in tableView: UITableView, with animation: UITableView.RowAnimation) {}
    func insertCell(for builder: TableViewCellBuilder, at indexPath: IndexPath, in tableView: UITableView, with animation: UITableView.RowAnimation) {}
    func removeBuilder(at indexPath: IndexPath) {
        self.builders.remove(at: indexPath.row)
    }

    func appendBuilder(_ builder: TableViewCellBuilder) {
        self.builders.insert(builder, at: 0)
    }


}
