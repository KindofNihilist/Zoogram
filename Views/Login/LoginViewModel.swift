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

    func loginUser(with email: String, password: String) async {
        do {
            let loggedInUser = try await service.loginUser(with: email, password: password)
            print("logged in userID: ", loggedInUser.userID)
            UserManager.shared.setDefaultsForNewlyLoggedInUser(loggedInUser)
        } catch {
            self.errorHandler?(error.localizedDescription)
        }
    }

    func resetPassword(for email: String) async {
        do {
            try await service.resetPassword(for: email)
        } catch {
            self.errorHandler?(error.localizedDescription)
        }
    }
}
