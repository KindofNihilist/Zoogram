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


    func checkIfUsernameIsValid(username: String) throws {
        try service.checkIfUsernameIsValid(username: username)
    }

    func checkIfUsernameIsAvailable(username: String) async throws -> Bool {
        return try await service.checkIfUsernameIsAvailable(username: username)
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

    func checkIfNewValuesAreValid() async throws {
        guard changedValues.isEmpty != true else {
            return
        }

        if let newName = changedValues["name"] as? String {
            try service.checkIfNameIsValid(name: newName)
        }

        if let newUsername = changedValues["username"] as? String {
            try service.checkIfUsernameIsValid(username: newUsername)
            let isAvailable = try await service.checkIfUsernameIsAvailable(username: newUsername)
            if isAvailable == false {
                throw UsernameValidationError.taken
            }
        }
    }

    func saveChanges() async throws {
        if let newProfilePicture = newProfilePicture {
            try await UserDataService.shared.updateUserProfilePicture(newProfilePic: newProfilePicture)
        }
        try await UserDataService.shared.updateUserProfile(with: self.changedValues)
        
        print("Changed values", changedValues)
    }
}
