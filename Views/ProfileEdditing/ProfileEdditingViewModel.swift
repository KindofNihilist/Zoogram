//
//  ProfileEdditingViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 01.10.2022.
//

import Foundation
import SDWebImage

enum ProfileFormKind {
    case name, username, bio, email, gender
}

struct EditProfileFormModel {
    let label: String
    let placeholder: String
    var value: String?
    let formKind: ProfileFormKind
}

class ProfileEdditingViewModel {

    private let service: UserDataValidationServiceProtocol

    var name: String
    var username: String
    var bio: String?
    var email: String
    var gender: String
    var currentProfilePicture: UIImage
    var newProfilePicture: UIImage?

    var hasChangedProfilePic: Bool = false
    var generalInfoModels = [EditProfileFormModel]()
    var privateInfoModels = [EditProfileFormModel]()
    var changedValues = [String: Any]()

    let nameLocalizedTitle = String(localized: "Name")
    let namePlaceholder = String(localized: "Enter name")
    let usernameLocalizedTitle = String(localized: "Username")
    let usernamePlaceholder = String(localized: "Enter username")
    let bioLocalizedTitle = String(localized: "Bio")
    let bioPlaceholder = String(localized: "Enter bio")
    let emailLocalizedTitle = String(localized: "Email")
    let emailPlaceholder = String(localized: "Enter email")
    let genderLocalizedTitle = String(localized: "Gender")
    let genderPlaceholder = String(localized: "Choose gender")

    init(userViewModel: UserProfileViewModel, service: UserDataValidationServiceProtocol) {
        self.service = service
        self.name = userViewModel.user.name
        self.username = userViewModel.user.username
        self.bio = userViewModel.user.bio
        self.email = userViewModel.user.email
        self.gender = userViewModel.user.gender
        self.currentProfilePicture = userViewModel.user.getProfilePhoto()!
    }


    func checkIfUsernameIsValid(username: String, completion: @escaping (VoidResultWithErrorDescription) -> Void) {
        service.checkIfUsernameIsValid(username: username, completion: { result in
            completion(result)
        })
    }

    func checkIfUsernameIsAvailable(username: String, completion: @escaping (Result<IsAvailable, Error>) -> Void) {
        service.checkIfUsernameIsAvailable(username: username) { result in
            completion(result)
        }
    }

    func configureModels() {
        generalInfoModels.removeAll()
        privateInfoModels.removeAll()
        generalInfoModels = [EditProfileFormModel(label: nameLocalizedTitle, placeholder: namePlaceholder, value: name, formKind: .name),
                             EditProfileFormModel(label: usernameLocalizedTitle, placeholder: usernamePlaceholder, value: username, formKind: .username),
                             EditProfileFormModel(label: bioLocalizedTitle, placeholder: bioPlaceholder, value: bio, formKind: .bio)]

        privateInfoModels = [EditProfileFormModel(label: emailLocalizedTitle, placeholder: emailPlaceholder, value: email, formKind: .email),
                             EditProfileFormModel(label: genderLocalizedTitle, placeholder: genderPlaceholder, value: gender, formKind: .gender)]
    }

    func hasEdditedUserProfile(data: EditProfileFormModel) {
        switch data.formKind {
        case .name:
            changedValues["name"] = data.value
        case .username:
            changedValues["username"] = data.value
        case .bio:
            changedValues["bio"] = data.value
        case .email:
            changedValues["email"] = data.value
        case .gender:
            changedValues["gender"] = data.value
        }
    }

    func checkIfNewValuesAreValid(completion: @escaping (VoidResultWithErrorDescription) -> Void) {
        guard changedValues.isEmpty != true else {
            completion(.success)
            return
        }
        var errorDescriptions: String = ""
        let dispatchGroup = DispatchGroup()
        
        if let newName = changedValues["name"] as? String {
            dispatchGroup.enter()
            service.checkIfNameIsValid(name: newName) { result in
                switch result {
                case .success:
                    print("cool")
                case .failure(let description):
                    errorDescriptions += "\n\(description)"
                }
                dispatchGroup.leave()
            }
        }

        if let newUsername = changedValues["username"] as? String {
            dispatchGroup.enter()
            service.checkIfUsernameIsValid(username: newUsername) { result in
                switch result {
                case .success:
                    self.service.checkIfUsernameIsAvailable(username: newUsername) { result in
                        print("cool")
                    }
                case .failure(let description):
                    errorDescriptions += "\n\(description)"
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            if errorDescriptions.isEmpty {
                completion(.success)
            } else {
                completion(.failure(errorDescriptions))
            }
        }
    }

    func saveChanges(completion: @escaping (VoidResult) -> Void) {
        if hasChangedProfilePic {
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            UserDataService.shared.updateUserProfilePicture(newProfilePic: newProfilePicture!) { result in
                if case .failure(let error) = result {
                    completion(.failure(error))
                }
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            UserDataService.shared.updateUserProfile(with: self.changedValues) { result in
                if case .failure(let error) = result {
                    completion(.failure(error))
                }
                dispatchGroup.leave()
            }
            dispatchGroup.notify(queue: .main) {
                completion(.success)
            }
        } else {
            print("Changed values", changedValues)
            UserDataService.shared.updateUserProfile(with: self.changedValues) { result in
                print("finished updating profile data")
                completion(result)
            }
        }
    }
}
