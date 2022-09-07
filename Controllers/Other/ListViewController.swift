//
//  ListViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 21.01.2022.
//

import UIKit

enum FollowState {
    case following // Indicates the current user is following the other user
    case notFollowing // Indicates the current user is not following the other user
}

struct UserRelationship {
    let username: String
    let name: String
    let type: FollowState
}

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let data: [UserRelationship]
    
    private var viewKind: CellType
    
    private let tableView: UITableView = {
       let tableView = UITableView()
        tableView.separatorStyle = .none
        return tableView
    }()
    
    init(data: [UserRelationship], viewKind: CellType) {
        self.data = data
        self.viewKind = viewKind
        super.init(nibName: nil, bundle: nil)
        
        switch viewKind {
        case .following:
            tableView.register(FollowingListTableViewCell.self, forCellReuseIdentifier: FollowingListTableViewCell.identifier)
        case .followers:
            tableView.register(FollowersListTableViewCell.self, forCellReuseIdentifier: FollowersListTableViewCell.identifier)
        }
        
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewKind {
        case .following:
            let cell = tableView.dequeueReusableCell(withIdentifier: FollowingListTableViewCell.identifier, for: indexPath) as! FollowingListTableViewCell
            cell.configure(with: data[indexPath.row])
            cell.delegate = self
            return cell
        case .followers:
            let cell = tableView.dequeueReusableCell(withIdentifier: FollowersListTableViewCell.identifier, for: indexPath) as! FollowersListTableViewCell
            cell.configure(with: data[indexPath.row])
            cell.delegate = self
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //Go to profile of selected user
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }
    
}

extension ListViewController: FollowingListTableViewCellDelegate, FollowersListTableViewCellDelegate {
    func didTapFollowUnfollowButton(model: UserRelationship) {
        switch model.type {
        case .following:
            // perform firebase update to unfollow
            break
        case .notFollowing:
            // perform firebase update to follow
            break
        }
    }
    
    func didTapRemoveButton(model: String) {
        
    }
}


