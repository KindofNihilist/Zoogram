//
//  LoginService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 31.01.2024.
//

import Foundation

protocol LoginServiceProtocol {
    func loginUser(with email: String, password: String, completion: @escaping (Result<ZoogramUser, Error>) -> Void)
    func resetPassword(for email: String, completion: @escaping (VoidResult) -> Void)
}

class LoginService: LoginServiceProtocol {

    func loginUser(with email: String, password: String, completion: @escaping (Result<ZoogramUser, Error>) -> Void) {
        AuthenticationService.shared.signInUsing(email: email, password: password) { result in
            switch result {
            case .success(let currentUser):
                completion(.success(currentUser))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func resetPassword(for email: String, completion: @escaping (VoidResult) -> Void) {
        AuthenticationService.shared.resetPassword(email: email) { result in
            switch result {
            case .success:
                completion(.success)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
