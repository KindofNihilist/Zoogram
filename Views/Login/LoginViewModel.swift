//
//  LoginViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.09.2022.
//

import Foundation

final class LoginViewModel {

    func loginUser(with email: String, password: String, completion: @escaping (Bool, String) -> Void) {
        AuthenticationManager.shared.signInUsing(email: email, password: password) { isSuccessful, resultDescription in
            if isSuccessful {
                completion(true, resultDescription)
            } else {
                completion(false, resultDescription)
            }
        }
    }
}
