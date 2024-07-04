//
//  LoginService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 31.01.2024.
//

import Foundation

protocol LoginServiceProtocol: Sendable {
    func loginUser(with email: String, password: String) async throws -> ZoogramUser
    func resetPassword(for email: String) async throws
}

final class LoginService: LoginServiceProtocol {

    func loginUser(with email: String, password: String) async throws -> ZoogramUser {
        let loggedInUser = try await AuthenticationService.shared.signInUsing(email: email, password: password)
        return loggedInUser
    }

    func resetPassword(for email: String) async throws {
        try await AuthenticationService.shared.resetPassword(email: email)
    }
}
