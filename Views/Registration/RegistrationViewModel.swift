//
//  RegistrationViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 07.10.2022.
//

import Foundation
import UIKit

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

    func createZoogramUserModel() -> NewUser? {
        guard let email = self.email,
              let username = self.username,
              let name = self.name,
              let birthday = self.dateOfBirth,
              let gender = self.gender
        else {
            return nil
        }
        return NewUser(
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

    func registerNewUser(completion: @escaping (Result<ZoogramUser, Error>) -> Void) {
        let newUser = createZoogramUserModel()
        newUser?.setProfilePhoto(self.profilePicture)
        service.registerNewUser(for: newUser, password: self.password) { result in
            completion(result)
        }
    }

    func checkIfEmailIsAvailable(email: String, completion: @escaping (Result<IsAvailable, Error>) -> Void) {
        service.checkIfEmailIsAvailable(email: email) { result in
            completion(result)
        }
    }

    func checkIfUsernameIsAvailable(username: String, completion: @escaping (Result<IsAvailable, Error>) -> Void) {
        service.checkIfUsernameIsAvailable(username: username) { result in
            completion(result)
        }
    }

    func checkIfUsernameIsValid(username: String, completion: @escaping (VoidResultWithErrorDescription) -> Void) {
        service.checkIfUsernameIsValid(username: username) { result in
            completion(result)
        }
    }

    func checkIfPasswordIsValid(password: String, completion: @escaping (VoidResultWithErrorDescription) -> Void) {
        service.checkIfPasswordIsValid(password: password) { result in
            completion(result)
        }
    }

    func isValidEmail(email: String) -> Bool {
        service.checkIfEmailIsValid(email: email)
    }
}
