//
//  ProfileEdditingViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 01.10.2022.
//

import Foundation
import SDWebImage

enum profileFormKind {
    case name, username, bio, phone, email, gender
}

struct EditProfileFormModel {
    let label: String
    let placeholder: String
    var value: String?
    let formKind: profileFormKind
}

class ProfileEdditingViewModel {
    
    var name: String = ""
    var username: String = ""
    var bio: String = ""
    var email: String = ""
    var phoneNumber: String = ""
    var profilePictureURL: String = ""
    var gender: String = ""
    var newProfilePicture: UIImage?
    
    var hasChangedProfilePic: Bool = false
    var models = [[EditProfileFormModel]]()
    var changedValues = [String: Any]()
    
    
    
    func getUserProfileData(completion: @escaping () -> Void) {
        DatabaseManager.shared.getUser(for: AuthenticationManager.shared.getCurrentUserUID()) { user in
            guard let user = user else {
                return
            }
            self.name = user.name
            self.username = user.username
            self.bio = user.bio ?? ""
            self.email = user.email
            self.phoneNumber = user.phoneNumber ?? ""
            self.profilePictureURL = user.profilePhotoURL
            self.gender = user.gender ?? "Not Specified"
            self.configureModels()
            completion()
        }
    }
    
    func configureModels() {
        print(name, username, bio, email)
        //name, username, website, bio
        let section1 = [EditProfileFormModel(label: "Name", placeholder: "Name", value: name, formKind: .name),
                        EditProfileFormModel(label: "Username", placeholder: "Username", value: username, formKind: .username),
                        EditProfileFormModel(label: "Bio", placeholder: "Bio", value: bio, formKind: .bio)]
        models.append(section1)
        
        //private phone, email, gender
        let section2 = [EditProfileFormModel(label: "Phone", placeholder: "Phone", value: phoneNumber, formKind: .phone),
                        EditProfileFormModel(label: "Email", placeholder: "Email", value: email, formKind: .email),
                        EditProfileFormModel(label: "Gender", placeholder: "Gender", value: gender, formKind: .gender)]
        models.append(section2)
    }
    
    func getProfilePicture(completion: @escaping (UIImage) -> Void) {
        print(name, username, bio, email)
        SDWebImageManager.shared.loadImage(with: URL(string: profilePictureURL), options: [], progress: nil) { image, data, error, cache, bool, url in
            if let image = image {
                completion(image)
            }
        }
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
        case .phone:
            changedValues["phoneNumber"] = data.value
        case .gender:
            changedValues["gender"] = data.value
        }
    }
    
    
    func saveChanges(completion: @escaping () -> Void) {
        if hasChangedProfilePic {
            DatabaseManager.shared.updateUserProfilePicture(newProfilePic: newProfilePicture!)
            
            DatabaseManager.shared.updateUserProfile(with: self.changedValues) {
                completion()
            }
        } else {
            DatabaseManager.shared.updateUserProfile(with: self.changedValues) {
                completion()
            }
        }
    }
}
