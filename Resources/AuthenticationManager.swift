//
//  AuthenticationManager.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//
import FirebaseAuth 

public class AuthenticationManager {
    
    static let shared = AuthenticationManager()
    
    static let currentUserUID = Auth.auth().currentUser?.uid
    static let currentUserEmail = Auth.auth().currentUser?.email
    
    public func registerNewUser(username: String, email: String, password: String, completion: @escaping (Bool, String) -> Void) {
        Auth.auth().fetchSignInMethods(forEmail: email) { providers, error in
            
            guard providers != nil else {
                DatabaseManager.shared.checkIfUsernameIsTaken(with: email, username: username) { usernameTaken in
                    if usernameTaken {
                        completion(false, "Username is already taken")
                    } else {
                        
                        Auth.auth().createUser(withEmail: email, password: password) { result, error in
                            guard error == nil, result != nil else {
                                completion(false, "Firebase authentication error")
                                return
                            }
                            completion(true, "Account registered succesfully")
                        }
                    }
                }
                return
            }
            completion(false, "User with this email already exists")
        }
        
    }
    
    public func loginUser(username: String?, email: String?, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        if let email = email {
            //email log in
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                guard authResult != nil, error == nil else {
                    completion(.failure(error!))
                    return
                }
                DatabaseManager.shared.getUser(for: authResult!.user.uid) { result in
                    switch result {
                    case .success(let userData):
                        completion(.success(userData))
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        } else if let username = username {
            //username log in
        }
    }
    
    public func logOut(completion: (Bool) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(true)
            return
        } catch {
            print(error)
            completion(false)
            return
        }
    }
}

