//
//  AuthenticationManager.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//
import FirebaseAuth

public class AuthenticationManager {

    static let shared = AuthenticationManager()

    typealias IsSuccessful = Bool

    typealias UserID = String

    typealias ErrorDescription = String

    func createNewUser(email: String, password: String, completion: @escaping (IsSuccessful, UserID, String) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error as? NSError {
                switch AuthErrorCode.Code(rawValue: error.code) {
                case .operationNotAllowed:
                    completion(false, "", "Registration is disabled by administrator")
                case .emailAlreadyInUse:
                    completion(false, "", "Email is already in use")
                case .invalidEmail:
                    completion(false, "", "Invalid email format")
                case .weakPassword:
                    completion(false, "", "Weak password")
                default:
                    print("Error: \(error.localizedDescription)")
                }
            } else {
                completion(true, authResult!.user.uid, "User signed up successfully")
            }
        }
    }

    func updateUserProfileURL(profilePhotoURL: URL, completion: @escaping () -> Void) {
       let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.photoURL = profilePhotoURL
        changeRequest?.commitChanges(completion: { _ in
            completion()
        })
    }


    func signInUsing(email: String, password: String, completion: @escaping (IsSuccessful, ErrorDescription) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error as? NSError {
                switch AuthErrorCode.Code(rawValue: error.code) {
                case .operationNotAllowed:
                    completion(false, "Administrator has disabled this login option")
                case .userDisabled:
                    completion(false, "The account has been disabled")
                case .wrongPassword:
                    completion(false, "Invalid password")
                case .invalidEmail:
                    completion(false, "Invalid email")
                case .userNotFound:
                    completion(false, "User with this email doesn't exist")
                default:
                    print(error.localizedDescription)
                }
            } else {
                completion(true, "Successfully signed in")
            }

        }
    }

    func checkIfEmailIsAvailable(email: String, completion: @escaping (Bool, String) -> Void) {
        Auth.auth().fetchSignInMethods(forEmail: email) { signInMethods, _ in
            if signInMethods == nil {
                completion(true, "Email is available")
            } else {
                completion(false, "User with this email is already registered")
            }
        }
    }

    func getCurrentUserProfilePhotoURL() -> URL? {
        return Auth.auth().currentUser?.photoURL
    }

    func getCurrentUserUID() -> String {
        return Auth.auth().currentUser!.uid
    }

    func signOut(completion: (IsSuccessful) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(true)
        } catch {
            print(error)
            completion(false)
        }
    }
}

enum StorageKeys: String {
    case users = "Users/"
    case posts = "Posts/"
    case postsLikes = "PostsLikes/"
    case profilePictures = "/ProfilePictues/"
    case images = "Images/"
}

enum StorageError: Error {
    case errorObtainingSnapshot
    case couldNotMapSnapshotValue
    case errorCreatingAPost
}
