//
//  UserManager.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 26.04.2024.
//

import Foundation

class UserManager {

    private var userDefaults = UserDefaults.standard

    private var currentUser: ZoogramUser?

    static let shared = UserManager()

    func getCurrentUser() -> ZoogramUser {
        if let currentUser = currentUser {
            return currentUser
        } else {
            fatalError("Current user model is nil")
        }
    }

    func updateCurrentUserModel(_ userModel: ZoogramUser) {
        currentUser = userModel
    }

    func setDefaultsForNewlyLoggedInUser(_ user: ZoogramUser) {
        setUserID(uid: user.userID)
        setUsername(username: user.username)
        updateCurrentUserModel(user)
    }

    // MARK: UserID

    func setUserID(uid: UserID?) {
        userDefaults.set(uid, forKey: UserManagerKeys.userID)
    }

    func getUserID() -> UserID {
        if let userID = userDefaults.value(forKey: UserManagerKeys.userID) as? String {
            return userID
        } else {
            fatalError("UserID value is nil")
        }
    }

    // MARK: Username

    func setUsername(username: String?) {
        userDefaults.set(username, forKey: UserManagerKeys.username)
    }

    func getUsername() -> String {
        if let username = userDefaults.value(forKey: UserManagerKeys.username) as? String {
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
