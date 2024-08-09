//
//  User.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.09.2022.
//

import Foundation
import UIKit

enum FollowStatus {
    case following // Indicates the current user is following the other user
    case notFollowing // Indicates the current user is not following the other user
}

enum Gender: LocalizableEnum {
    case male
    case female
    case other

    func localizedString() -> String {
        switch self {
        case .male:
            return String(localized: "Male")
        case .female:
            return String(localized: "Female")
        case .other:
            return String(localized: "Other")
        }
    }
}

struct ZoogramUser: Codable, Sendable {

    var isCurrentUserProfile: Bool {
        get {
            let currentUserID = UserManager.shared.getUserID()
            return currentUserID == userID
        }
    }

    var followStatus: FollowStatus?
    var userID: String
    var profilePhotoURL: String?
    fileprivate var profilePhoto: UIImage?
    var email: String
    var username: String
    var name: String
    var bio: String?
    var birthday: String
    var gender: String
    var posts: Int
    var joinDate: Double // TimeInterval

    init(userID: String, profilePhotoURL: String?, email: String, username: String, name: String, bio: String? = nil, birthday: String, gender: String, posts: Int, joinDate: Double) {
        self.userID = userID
        self.profilePhotoURL = profilePhotoURL
        self.email = email
        self.username = username
        self.name = name
        self.bio = bio
        self.birthday = birthday
        self.gender = gender
        self.posts = posts
        self.joinDate = joinDate
    }

    init(_ uid: UserID, isCurrentUser: Bool = false) {
        self.userID = uid
        self.profilePhotoURL = ""
        self.email = ""
        self.username = ""
        self.name = ""
        self.bio = ""
        self.birthday = ""
        self.gender = ""
        self.posts = 0
        self.joinDate = 0
        self.followStatus = .notFollowing
    }

    func createDictionary() -> [String: Any]? {
        guard let dictionary = self.dictionary else { return nil }
        return dictionary
    }

    func getProfilePhoto() -> UIImage? {
        return self.profilePhoto ?? nil
    }

    mutating func setProfilePhoto(_ photo: UIImage?) {
        if let photo = photo {
            self.profilePhoto = photo
        }
    }

    enum CodingKeys: CodingKey {
        case userID
        case profilePhotoURL
        case email
        case username
        case name
        case bio
        case birthday
        case gender
        case posts
        case joinDate
    }
}
