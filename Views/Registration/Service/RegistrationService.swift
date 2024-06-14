//
//  RegistrationService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 16.01.2024.
//

import Foundation

protocol RegistrationServiceProtocol: UserDataValidationServiceProtocol {
    func registerNewUser(for userModel: ZoogramUser, password: String) async throws -> ZoogramUser
    func uploadUserInfo(for userModel: ZoogramUser) async throws -> ZoogramUser
}

class RegistrationService: RegistrationServiceProtocol {

    private let userDataValidationService = UserDataValidationService()

    func checkIfNameIsValid(name: String) throws {
        try userDataValidationService.checkIfNameIsValid(name: name)
    }

    func registerNewUser(for userModel: ZoogramUser, password: String) async throws -> ZoogramUser {
        var userModel = userModel
        let registeredUserID = try await AuthenticationService.shared.createNewUser(email: userModel.email, password: password, username: userModel.username)
        userModel.userID = registeredUserID
        let uploadedUserModel = try await uploadUserInfo(for: userModel)
        return uploadedUserModel
    }

    func uploadUserInfo(for userModel: ZoogramUser) async throws -> ZoogramUser {
        var userModel = userModel
        if let image = userModel.getProfilePhoto() {
            let photoURL = try await UserDataService().uploadUserProfilePictureForNewlyCreatedaUser(with: userModel.userID, profilePic: image)
            userModel.profilePhotoURL = photoURL.absoluteString
        }

        try await UserDataService().insertNewUserData(with: userModel)
        return userModel
    }

    func checkIfEmailIsAvailable(email: String) async throws -> Bool {
        try await userDataValidationService.checkIfEmailIsAvailable(email: email)
    }

    func checkIfEmailIsValid(email: String) -> Bool {
        userDataValidationService.checkIfEmailIsValid(email: email)
    }

    func checkIfUsernameIsAvailable(username: String) async throws -> Bool {
        try await userDataValidationService.checkIfUsernameIsAvailable(username: username)
    }

    func checkIfUsernameIsValid(username: String) throws {
        try userDataValidationService.checkIfUsernameIsValid(username: username)
    }

    func checkIfPasswordIsValid(password: String) throws {
        try userDataValidationService.checkIfPasswordIsValid(password: password)
    }
}
