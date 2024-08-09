//
//  UserDataServiceMock.swift
//  ZoogramTests
//
//  Created by Artem Dolbiiev on 05.07.2024.
//

import Foundation
@testable import Zoogram
import UIKit.UIImage


 let fakeUserObject = ZoogramUser(
    userID: "currentUserID",
    profilePhotoURL: nil,
    email: "testUser@email.com",
    username: "testUsername",
    name: "testName",
    birthday: "7/12/1998",
    gender: "Male",
    posts: 0,
    joinDate: Date().timeIntervalSince1970)

final class UserDataServiceMock: UserDataServiceProtocol {

    func observeUser(with uid: String, completion: @escaping (Result<Zoogram.ZoogramUser, any Error>) -> Void) {
        completion(.success(fakeUserObject))
    }

    func getUser(for userID: Zoogram.UserID) async throws -> Zoogram.ZoogramUser {
        return fakeUserObject
    }

    func insertNewUserData(with userData: Zoogram.ZoogramUser) async throws {
        return
    }

    func checkIfUsernameIsAvailable(username: String) async throws -> Bool {
        return true
    }

    func updateUserProfile(with values: [String: Any]) async throws {
        return
    }

    func uploadUserProfilePictureForNewlyCreatedaUser(with uid: Zoogram.UserID, profilePic: UIImage) async throws -> URL {
        return URL(fileURLWithPath: "")
    }

    func updateUserProfilePicture(newProfilePic: UIImage) async throws {
        return
    }
}
