//
//  LoginViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.09.2022.
//

import Foundation

final class LoginViewModel {

    private var service: LoginServiceProtocol

    var errorHandler: ((ErrorDescription) -> Void)?

    init(service: LoginServiceProtocol) {
        self.service = service
    }

    func loginUser(with email: String, password: String, completion: @escaping (ZoogramUser) -> Void) {
        service.loginUser(with: email, password: password) { result in
            switch result {
            case .success(let loggedInUser):
                completion(loggedInUser)
            case .failure(let error):
                self.errorHandler?(error.localizedDescription)
            }
        }
    }

    func resetPassword(for email: String, completion: @escaping () -> Void) {
        service.resetPassword(for: email) { result in
            switch result {
            case .success:
                completion()
            case .failure(let error):
                self.errorHandler?(error.localizedDescription)
            }
        }
    }
}
