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

@MainActor
class ProfileEdditingViewModel {

    private let service: UserDataValidationServiceProtocol

    private var user: ZoogramUser!

    var hasChangedProfilePic: Bool = false
    var generalInfoModels = [EditProfileFormModel]()
    var privateInfoModels = [EditProfileFormModel]()
    var changedValues = [String: Sendable]()
    var newProfilePicture: UIImage?
    var currentProfilePicture: UIImage {
        return user.getProfilePhoto() ?? UIImage.profilePicturePlaceholder
    }

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

    init(service: UserDataValidationServiceProtocol) {
        self.service = service
    }

     func getCurrentUserModel() async {
        user = await UserManager.shared.getCurrentUser()
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
        generalInfoModels = [EditProfileFormModel(label: nameLocalizedTitle, placeholder: namePlaceholder, value: user.name, formKind: .name),
                             EditProfileFormModel(label: usernameLocalizedTitle, placeholder: usernamePlaceholder, value: user.username, formKind: .username),
                             EditProfileFormModel(label: bioLocalizedTitle, placeholder: bioPlaceholder, value: user.bio, formKind: .bio)]

        privateInfoModels = [EditProfileFormModel(label: emailLocalizedTitle, placeholder: emailPlaceholder, value: user.email, formKind: .email),
                             EditProfileFormModel(label: genderLocalizedTitle, placeholder: genderPlaceholder, value: user.gender, formKind: .gender)]
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
            try await UserDataService().updateUserProfilePicture(newProfilePic: newProfilePicture)
        }
        try await UserDataService().updateUserProfile(with: self.changedValues)
    }
}
