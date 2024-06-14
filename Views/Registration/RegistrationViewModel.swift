//
//  RegistrationViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 07.10.2022.
//

import Foundation
import UIKit

@MainActor
class RegistrationViewModel {

    private let service: RegistrationServiceProtocol

    var email: String?
    var username: String?
    var password: String?
    var name: String?
    var bio: String?
    var profilePicture: UIImage?
    var dateOfBirth: String?
    var gender: String?

    init(service: RegistrationServiceProtocol) {
        self.service = service
    }

    private func createZoogramUserModel() -> ZoogramUser? {
        guard let email = self.email,
              let username = self.username,
              let name = self.name,
              let birthday = self.dateOfBirth,
              let gender = self.gender
        else {
            return nil
        }

        return ZoogramUser(
            userID: "",
            profilePhotoURL: nil,
            email: email,
            username: username,
            name: name,
            bio: self.bio,
            birthday: birthday,
            gender: gender,
            posts: 0,
            joinDate: Date().timeIntervalSince1970)
    }

    func registerNewUser() async throws -> ZoogramUser {
        guard var userModel = createZoogramUserModel(),
              let password = self.password
        else {
            throw RegistrationError.dataMissing
        }
        userModel.setProfilePhoto(self.profilePicture)
        let registeredUser = try await service.registerNewUser(for: userModel, password: password)
        await UserManager.shared.setDefaultsForUser(registeredUser)
        return registeredUser
    }

    func checkIfEmailIsAvailable(email: String) async throws -> Bool {
        try await service.checkIfEmailIsAvailable(email: email)
    }

    func checkIfUsernameIsAvailable(username: String) async throws -> Bool {
        try await service.checkIfUsernameIsAvailable(username: username)
    }

    func checkIfUsernameIsValid(username: String) throws {
        try service.checkIfUsernameIsValid(username: username)
    }

    func checkIfPasswordIsValid(password: String) throws {
        try service.checkIfPasswordIsValid(password: password)
    }

    func isValidEmail(email: String) -> Bool {
        service.checkIfEmailIsValid(email: email)
    }
}

enum RegistrationError: LocalizedError {
    case dataMissing

    var errorDescription: String? {
        switch self {
        case .dataMissing:
            return String(localized: "Data required for registration is missing, try again.")
        }
    }
}
