//
//  PostTableViewCellBuilder.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 24.05.2023.
//

import UIKit.UITableView

class PostTableViewCellBuilder: TableViewCellBuilder {

    private let viewModel: PostViewModel

    private let identifier = PostTableViewCell.identifier

    private let delegate: PostTableViewCellProtocol

    var canEdit: Bool = false

    var editingStyle: UITableViewCell.EditingStyle = .none

    init(viewModel: PostViewModel, delegate: PostTableViewCellProtocol) {
        self.viewModel = viewModel
        self.delegate = delegate
    }

    func cellAt(indexPath: IndexPath, for tableView: UITableView) -> UITableViewCell {
        let cell: PostTableViewCell = tableView.dequeue(withIdentifier: identifier, for: indexPath)
        cell.configure(with: viewModel)
        cell.delegate = delegate
        return cell
    }

}
