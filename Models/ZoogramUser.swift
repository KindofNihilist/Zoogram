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

class ZoogramUser: Codable {

    var isCurrentUserProfile = false
    var hasPosts: Bool = false
    var followStatus: FollowStatus!
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
    var joinDate: Double //TimeInterval


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
        self.isCurrentUserProfile = checkIfCurrentUser(uid: userID)
    }

    init(isCurrentUser: Bool = false) {
        self.userID = ""
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
        self.isCurrentUserProfile = isCurrentUser
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userID = try container.decode(String.self, forKey: .userID)
        self.profilePhotoURL = try container.decodeIfPresent(String.self, forKey: .profilePhotoURL)
        self.email = try container.decode(String.self, forKey: .email)
        self.username = try container.decode(String.self, forKey: .username)
        self.name = try container.decode(String.self, forKey: .name)
        self.bio = try container.decodeIfPresent(String.self, forKey: .bio)
        self.birthday = try container.decode(String.self, forKey: .birthday)
        self.gender = try container.decode(String.self, forKey: .gender)
        self.posts = try container.decode(Int.self, forKey: .posts)
        self.joinDate = try container.decode(Double.self, forKey: .joinDate)
        self.hasPosts = try container.decode(Bool.self, forKey: .hasPosts)
        self.isCurrentUserProfile = checkIfCurrentUser(uid: userID)
    }

    func createDictionary() -> [String: Any]? {
        guard let dictionary = self.dictionary else { return nil }
        return dictionary
    }

    func getProfilePhoto() -> UIImage? {
        return self.profilePhoto ?? UIImage(systemName: "person.crop.circle.fill")
    }

    func setProfilePhoto(_ photo: UIImage?) {
        if let photo = photo {
            self.profilePhoto = photo
        }
    }

    private func checkIfCurrentUser(uid: String) -> Bool {
        let currentUserID = AuthenticationService.shared.getCurrentUserUID()
        return currentUserID == uid
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
        case hasPosts
    }
}

class NewUser: ZoogramUser {
    
    override func getProfilePhoto() -> UIImage? {
        return self.profilePhoto ?? nil
    }
}


