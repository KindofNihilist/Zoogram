//
//  FollowerCellController.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 29.01.2024.
//

import Foundation

class FollowerCellController: GenericCellController<FollowerTableViewCell> {

    private let follower: ZoogramUser
    private let action: ((IndexPath) -> Void)?
    private weak var delegate: FollowListCellDelegate?

    init(follower: ZoogramUser, delegate: FollowListCellDelegate?, action: @escaping ((IndexPath) -> Void)) {
        self.follower = follower
        self.delegate = delegate
        self.action = action
    }

    override func configureCell(_ cell: FollowerTableViewCell, at indexPath: IndexPath? = nil) {
        cell.configure(for: self.follower)
        cell.delegate = self.delegate
        cell.backgroundColor = Colors.background
    }

    override func didSelectCell(at indexPath: IndexPath) {
        action?(indexPath)
    }
}
