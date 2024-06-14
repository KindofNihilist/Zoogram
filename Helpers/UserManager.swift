//
//  UserManager.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 26.04.2024.
//

import Foundation

actor UserManager {

    private var currentUser: ZoogramUser?

    static let shared = UserManager()

    func getCurrentUser() -> ZoogramUser {
        if let currentUser = currentUser {
            return currentUser
        } else {
            return ZoogramUser(getUserID(), isCurrentUser: true)
        }
    }

    func updateCurrentUserModel(_ userModel: ZoogramUser) {
        currentUser = userModel
    }

    func setDefaultsForUser(_ user: ZoogramUser) {
        setUserID(uid: user.userID)
        setUsername(username: user.username)
        updateCurrentUserModel(user)
    }

    // MARK: UserID
    func setUserID(uid: UserID?) {
        UserDefaults.standard.set(uid, forKey: UserManagerKeys.userID)
    }

    nonisolated func getUserID() -> UserID {
        if let userID = UserDefaults.standard.value(forKey: UserManagerKeys.userID) as? String {
            return userID
        } else {
            fatalError("UserID value is nil")
        }
    }

    // MARK: Username
    func setUsername(username: String?) {
        UserDefaults.standard.set(username, forKey: UserManagerKeys.username)
    }

    nonisolated func getUsername() -> String {
        if let username = UserDefaults.standard.value(forKey: UserManagerKeys.username) as? String {
            return username
        } else {
            fatalError("Username isn't set")
        }
    }
}

struct UserManagerKeys {
    static let userID = "LOGGED_IN_USER_ID"
    static let profilePictureURL = "PROFILE_PICTURE_URL"
    static let username = "USER_NAME"
}
