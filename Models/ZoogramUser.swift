//
//  User.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.09.2022.
//

import Foundation

class ZoogramUser: Codable {
    
    var isUserProfile = false
    var isFollowed: FollowStatus!
    
    var userID: String
    var profilePhotoURL: String
    var email: String
    var phoneNumber: String?
    var username: String
    var name: String
    var bio: String?
    var birthday: String
    var gender: String?
    var posts: Int
    var joinDate: Double //TimeInterval
    

    init(userID: String, profilePhotoURL: String, email: String, phoneNumber: String? = nil, username: String, name: String, bio: String? = nil, birthday: String, gender: String? = nil, posts: Int, joinDate: Double) {
        self.userID = userID
        self.profilePhotoURL = profilePhotoURL
        self.email = email
        self.phoneNumber = phoneNumber
        self.username = username
        self.name = name
        self.bio = bio
        self.birthday = birthday
        self.gender = gender
        self.posts = posts
        self.joinDate = joinDate
        self.isUserProfile = checkIfCurrentUser(uid: userID)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userID = try container.decode(String.self, forKey: .userID)
        self.profilePhotoURL = try container.decode(String.self, forKey: .profilePhotoURL)
        self.email = try container.decode(String.self, forKey: .email)
        self.phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        self.username = try container.decode(String.self, forKey: .username)
        self.name = try container.decode(String.self, forKey: .name)
        self.bio = try container.decodeIfPresent(String.self, forKey: .bio)
        self.birthday = try container.decode(String.self, forKey: .birthday)
        self.gender = try container.decodeIfPresent(String.self, forKey: .gender)
        self.posts = try container.decode(Int.self, forKey: .posts)
        self.joinDate = try container.decode(Double.self, forKey: .joinDate)
        self.isUserProfile = checkIfCurrentUser(uid: userID)
    }
    
    func createDictionary() -> [String: Any]? {
        guard let dictionary = self.dictionary else { return nil }
        return dictionary
    }
    
    func checkIfCurrentUser(uid: String) -> Bool {
        if uid == AuthenticationManager.shared.getCurrentUserUID() {
            return true
        } else {
            return false
        }
    }
    
//    func checkIfFollowedByCurrentUser(completion: @escaping () -> Void) {
//        FollowService.shared.checkFollowStatus(for: userID) { followStatus in
//            print("FOLLOW STATUS", followStatus)
//            self.isFollowed = followStatus
//            completion()
//        }
//    }
    
    enum CodingKeys: CodingKey {
        case userID
        case profilePhotoURL
        case email
        case phoneNumber
        case username
        case name
        case bio
        case birthday
        case gender
        case posts
        case joinDate
    }
}
