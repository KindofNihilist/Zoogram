//
//  Factory.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 29.01.2024.
//

import UIKit.UITableView

protocol FollowListFactory: AnyObject {
    var delegate: FollowListCellDelegate { get set }
    var selectionAction: ((IndexPath) -> Void)? { get set }
    func buildSections(for users: [ZoogramUser], completion: @escaping ([TableSectionController]) -> Void)
}

class FollowersListFactory: FollowListFactory {

    var tableView: UITableView

    var delegate: FollowListCellDelegate

    var selectionAction: ((IndexPath) -> Void)?

    var sections = [TableSectionController]()

    init(tableView: UITableView, delegate: FollowListCellDelegate) {
        self.tableView = tableView
        self.delegate = delegate
    }

    func buildSections(for users: [ZoogramUser], completion: @escaping ([TableSectionController]) -> Void) {
        let followersCellControllers = users.map { user in
            return FollowerCellController(follower: user, delegate: self.delegate) { indexPath in
                self.selectionAction?(indexPath)
            }
        }
        let section = FollowListSection(sectionHolder: self.tableView, cellControllers: followersCellControllers, sectionIndex: 0)
        self.sections.append(section)
        completion(self.sections)
    }
}

class FollowingListFactory: FollowersListFactory {

    override func buildSections(for users: [ZoogramUser], completion: @escaping ([TableSectionController]) -> Void) {
        let followedUsersCellControllers = users.map { user in
            return FollowedCellController(followedUser: user, delegate: self.delegate) { indexPath in
                self.selectionAction?(indexPath)
            }
        }
        let section = FollowListSection(sectionHolder: self.tableView, cellControllers: followedUsersCellControllers, sectionIndex: 0)
        self.sections.append(section)
        completion(self.sections)
    }
}
