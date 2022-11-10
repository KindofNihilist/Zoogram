//
//  ListViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 21.01.2022.
//

import UIKit

struct UserRelationship {
    let username: String
    let name: String
    let type: FollowStatus
}

class FollowListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let viewModel = FollowListViewModel()
    
    private var viewKind: FollowCellType
    
    private var isUserProfile: Bool
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        return tableView
    }()
    
    init(for uid: String, isUserProfile: Bool, viewKind: FollowCellType) {
        self.isUserProfile = isUserProfile
        self.viewKind = viewKind
        self.viewModel.uid = uid
        super.init(nibName: nil, bundle: nil)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(FollowingListTableViewCell.self, forCellReuseIdentifier: FollowingListTableViewCell.identifier)
        tableView.register(FollowersListTableViewCell.self, forCellReuseIdentifier: FollowersListTableViewCell.identifier)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view = tableView
        
        switch viewKind {
            
        case .following:
            viewModel.getFollowing() {
                self.tableView.reloadData()
            }
            
        case .followers:
            viewModel.getFollowers() {
                self.tableView.reloadData()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = viewModel.users[indexPath.row]
        
        if isUserProfile {
            switch viewKind {
                
            case .following:
                let cell = tableView.dequeueReusableCell(withIdentifier: FollowingListTableViewCell.identifier, for: indexPath) as! FollowingListTableViewCell
                cell.nameLabel.text = user.name
                cell.usernameLabel.text = user.username
                cell.profileImageView.sd_setImage(with: URL(string: user.profilePhotoURL))
                print("USER FOLLOW STATUS:", user.isFollowed)
                cell.configure(userID: user.userID ,followStatus: user.isFollowed)
                cell.delegate = self
                return cell
                
            case .followers:
                let cell = tableView.dequeueReusableCell(withIdentifier: FollowersListTableViewCell.identifier, for: indexPath) as! FollowersListTableViewCell
                cell.nameLabel.text = user.name
                cell.usernameLabel.text = user.username
                cell.profileImageView.sd_setImage(with: URL(string: user.profilePhotoURL))
                cell.configure(userID: user.userID, followStatus: user.isFollowed)
                cell.delegate = self
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: FollowingListTableViewCell.identifier, for: indexPath) as! FollowingListTableViewCell
            cell.nameLabel.text = user.name
            cell.usernameLabel.text = user.username
            cell.profileImageView.sd_setImage(with: URL(string: user.profilePhotoURL))
            cell.delegate = self
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = viewModel.users[indexPath.row]
        let vc = UserProfileViewController(for: user.userID, isUserProfile: user.isUserProfile, isFollowed: user.isFollowed)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }
    
}

extension FollowListViewController: FollowListCellDelegate {
    func removeButtonTapped(userID: String, removeCompletion: @escaping (FollowStatus) -> Void) {
        viewModel.removeUserFollowingMe(uid: userID) { success in
            if success {
                removeCompletion(.notFollowing)
            }
        }
    }
    
    func undoButtonTapped(userID: String, undoCompletion: @escaping (FollowStatus) -> Void) {
        viewModel.undoUserRemoval(uid: userID) { success in
            if success {
                undoCompletion(.following)
            }
        }
    }
    
    func followButtonTapped(userID: String, followCompletion: @escaping (FollowStatus) -> Void) {
        viewModel.followUser(uid: userID) { success in
            if success {
                followCompletion(.following)
            }
        }
    }
    
    func unfollowButtonTapped(userID: String, unfollowCompletion: @escaping (FollowStatus) -> Void) {
        viewModel.unfollowUser(uid: userID) { success in
            if success {
                unfollowCompletion(.notFollowing)
            }
        }
    }
}


