//
//  FollowedListViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 30.01.2024.
//

import Foundation

class FollowedListViewController: FollowersListViewController {

    override func setFactory() {
        self.factory = FollowingListFactory(tableView: self.tableView, delegate: self)
    }

    override func configureMessageView(isUserProfile: Bool) {
        let localizedTitle = String(localized: "Followed")
        var localizedMessage: String

        if isUserProfile {
            localizedMessage = String(localized: "When you follow someone, \nyou'll see them here.")
        } else {
            localizedMessage = String(localized: "This user is not following anyone")
        }
        messageTitle.text = localizedTitle
        message.text = localizedMessage
    }
}
