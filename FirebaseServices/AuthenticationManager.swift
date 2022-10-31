//
//  AuthenticationManager.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//
import FirebaseAuth 

public class AuthenticationManager {
    
    static let shared = AuthenticationManager()
    
    public func createNewUser(email: String, password: String, completion: @escaping (Bool, String, String) -> Void) {
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
                completion(true, self.getCurrentUserUID(), "User signed up successfully")
            }
        }
    }
    
    public func signInUsing(email: String, password: String, completion: @escaping (Bool, String) -> Void) {
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
                completion(true, "Succesfully logged in")
            }

        }
    }
    
    public func checkIfEmailIsAvailable(email: String, completion: @escaping (Bool, String) -> Void) {
        Auth.auth().fetchSignInMethods(forEmail: email) { signInMethods, error in
            if signInMethods == nil {
                completion(true, "Email is available")
            } else {
                completion(false, "User with this email is already registered")
            }
        }
    }
    
    
    public func getCurrentUserUID() -> String {
        return Auth.auth().currentUser!.uid
    }
    
    
    public func signOut(completion: (Bool) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(true)
        } catch {
            print(error)
            completion(false)
        }
    }
}

