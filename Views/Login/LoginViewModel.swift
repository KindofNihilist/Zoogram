//
//  LoginViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.09.2022.
//

import Foundation

final class LoginViewModel {
    
    func loginUser(with username: String, email: String = "", password: String, completion: @escaping (Bool) -> Void) {
        AuthenticationManager.shared.loginUser(username: username, email: email, password: password) { result in
            
            switch result {
                
            case .success:
                completion(true)
                print("Succesfully Logged In")
//                UserDefaults.standard.set(email, forKey: "email")
//                UserDefaults.standard.set(username, forKey: "username")
                
            case .failure(let error):
                completion(false)
                print(error)
            }
        }
    }
    
    
}
