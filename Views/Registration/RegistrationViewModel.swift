//
//  RegistrationViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 07.10.2022.
//

import Foundation
import UIKit

class RegistrationViewModel {
    
    private var newUser: ZoogramUser!
    
    func fillInBasicZoogramUserModel(userID: String, email: String, username: String) {
        newUser = ZoogramUser(userID: "",
                              profilePhotoURL: "",
                              email: email,
                              username: username,
                              name: "",
                              birthday: "",
                              following: 0,
                              followers: 0,
                              posts: 0,
                              joinDate: Date().timeIntervalSince1970)
        
    }
    
    func registerNewUserWith(email: String, username: String, password: String, completion: @escaping (Bool, String) -> Void) {
        
        AuthenticationManager.shared.createNewUser(email: email, password: password) { success, userID, errorDescription in
            if success {
                self.fillInBasicZoogramUserModel(userID: userID, email: email, username: username)
                DatabaseManager.shared.insertNewUser(with: self.newUser) { success in
                    if success {
                        completion(true, "")
                    } else {
                        completion(false, "Firebase user insertion error")
                    }
                }
            } else {
                completion(false, errorDescription)
            }
        }
    }
    
    func addUserInfo(name: String, bio: String, profilePic: UIImage?, completion: @escaping () -> Void) {
        let dict = ["name" : name, "bio" : bio]
        
        if let image = profilePic {
            DatabaseManager.shared.updateUserProfilePicture(newProfilePic: image)
        }
        
        DatabaseManager.shared.updateUserProfile(with: dict) {
            completion()
        }
    }
    
    func finishSignUp(dateOfBirth: String, gender: String, completion: @escaping () -> Void) {
        let dict = ["gender" : gender, "birthday" : dateOfBirth]
        DatabaseManager.shared.updateUserProfile(with: dict) {
            completion()
        }
    }
    
    func checkIfEmailIsAvailable(email: String, completion: @escaping (Bool, String) -> Void) {
        AuthenticationManager.shared.checkIfEmailIsAvailable(email: email) { isAvailable, description in
            switch isAvailable {
            case true: completion(true, description)
            case false: completion(false, description)
            }
        }
    }
    
    func checkIfUsernameIsAvailable(username: String, completion: @escaping (Bool) -> Void) {
        DatabaseManager.shared.checkIfUsernameIsAvailable(username: username) { isAvailable in
            completion(isAvailable)
        }
    }
    
    func isValidEmail(email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
}
