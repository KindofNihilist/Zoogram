//
//  FollowedCellController.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 29.01.2024.
//

import Foundation

class FollowedCellController: GenericCellController<FollowedTableViewCell> {

    private let followedUser: ZoogramUser
    private let action: ((IndexPath) -> Void)?
    private weak var delegate: FollowListCellDelegate?

    init(followedUser: ZoogramUser, delegate: FollowListCellDelegate?, action: @escaping ((IndexPath) -> Void)) {
        self.followedUser = followedUser
        self.delegate = delegate
        self.action = action
    }

    override func configureCell(_ cell: FollowedTableViewCell, at indexPath: IndexPath? = nil) {
        cell.configure(user: self.followedUser)
        cell.delegate = self.delegate
        cell.backgroundColor = Colors.background
    }

    override func didSelectCell(at indexPath: IndexPath) {
        action?(indexPath)
    }
}
