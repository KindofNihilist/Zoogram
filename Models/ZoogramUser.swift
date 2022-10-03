//
//  User.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.09.2022.
//

import Foundation

public struct ZoogramUser: Codable {
    var profilePhotoURL: String
    var email: String
    var phoneNumber: String?
    var username: String
    var name: String
    var bio: String?
    var birthday: String
    var gender: String?
    var following: Int
    var followers: Int
    var posts: Int
    var joinDate: Double //TimeInterval
    
}

struct UserProfileCounts {
    let followers: Int
    let following: Int
    let posts: Int
}
