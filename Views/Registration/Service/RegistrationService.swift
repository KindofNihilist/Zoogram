//
//  RegistrationService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 16.01.2024.
//

import Foundation

protocol RegistrationServiceProtocol: UserDataValidationServiceProtocol {
    func registerNewUser(for userModel: NewUser?, password: String?, completion: @escaping (Result<ZoogramUser, Error>) -> Void)
    func uploadUserInfo(for userModel: NewUser, completion: @escaping (Result<ZoogramUser, Error>) -> Void)
}

class RegistrationService: RegistrationServiceProtocol {

    private let userDataValidationService = UserDataValidationService()
    
    func checkIfNameIsValid(name: String, completion: @escaping (VoidResultWithErrorDescription) -> Void) {
        userDataValidationService.checkIfNameIsValid(name: name) { result in
            completion(result)
        }
    }

    func registerNewUser(for userModel: NewUser?, password: String?, completion: @escaping (Result<ZoogramUser, Error>) -> Void) {
        guard let newUser = userModel,
              let password = password
        else {
            return
        }

        AuthenticationService.shared.createNewUser(email: newUser.email, password: password, username: newUser.username) { [weak self, newUser] result in
            switch result {
            case .success(let registeredUserID):
                newUser.userID = registeredUserID
                self?.uploadUserInfo(for: newUser, completion: { result in
                    switch result {
                    case .success:
                        completion(.success(newUser))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func uploadUserInfo(for userModel: NewUser, completion: @escaping (Result<ZoogramUser, Error>) -> Void) {
        let dispatchGroup = DispatchGroup()

        if let image = userModel.getProfilePhoto() {
            dispatchGroup.enter()
            UserDataService.shared.uploadUserProfilePictureForNewlyCreatedaUser(with: userModel.userID, profilePic: image) { result in
                switch result {
                case .success(let profilePicURL):
                    userModel.profilePhotoURL = profilePicURL
                case .failure(let error):
                    completion(.failure(error))
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            UserDataService.shared.insertNewUserData(with: userModel) { result in
                switch result {
                case .success:
                    completion(.success(userModel))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func checkIfEmailIsAvailable(email: String, completion: @escaping (Result<IsAvailable, Error>) -> Void) {
        userDataValidationService.checkIfEmailIsAvailable(email: email) { result in
            completion(result)
        }
    }

    func checkIfEmailIsValid(email: String) -> Bool {
        userDataValidationService.checkIfEmailIsValid(email: email)
    }
    
    func checkIfUsernameIsAvailable(username: String, completion: @escaping (Result<IsAvailable, Error>) -> Void) {
        userDataValidationService.checkIfUsernameIsAvailable(username: username) { result in
            completion(result)
        }
    }
    
    func checkIfUsernameIsValid(username: String, completion: @escaping (VoidResultWithErrorDescription) -> Void) {
        userDataValidationService.checkIfUsernameIsValid(username: username) { result in
            completion(result)
        }
    }
    
    func checkIfPasswordIsValid(password: String, completion: @escaping (VoidResultWithErrorDescription) -> Void) {
        userDataValidationService.checkIfPasswordIsValid(password: password) { result in
            completion(result)
        }
    }
}
