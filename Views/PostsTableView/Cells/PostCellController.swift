//
//  PostTableViewCellBuilder.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 24.05.2023.
//

import UIKit.UITableView

class PostCellController: GenericCellController<PostTableViewCell> {

    private let viewModel: PostViewModel

    private let delegate: PostTableViewCellProtocol

    var canEdit: Bool = false

    var editingStyle: UITableViewCell.EditingStyle = .none

    init(viewModel: PostViewModel, delegate: PostTableViewCellProtocol) {
        self.viewModel = viewModel
        self.delegate = delegate
    }

    override func configureCell(_ cell: PostTableViewCell) {
        cell.configure(with: viewModel)
        cell.delegate = self.delegate
    }

}
