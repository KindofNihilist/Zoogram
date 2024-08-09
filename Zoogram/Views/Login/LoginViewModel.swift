//
//  LoginViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.09.2022.
//

import Foundation

@MainActor
final class LoginViewModel {

    private var service: LoginServiceProtocol

    init(service: LoginServiceProtocol) {
        self.service = service
    }

    func loginUser(with email: String, password: String) async throws {
        let loggedInUser = try await service.loginUser(with: email, password: password)
        await UserManager.shared.setDefaultsForUser(loggedInUser)
    }

    func resetPassword(for email: String) async throws {
        try await service.resetPassword(for: email)
    }
}
