//
//  UserProfileDataValidationService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 16.01.2024.
//

import Foundation

protocol UserDataValidationServiceProtocol: Sendable {
    func checkIfEmailIsAvailable(email: String) async throws -> Bool
    func checkIfEmailIsValid(email: String) -> Bool
    func checkIfUsernameIsAvailable(username: String) async throws -> Bool
    func checkIfUsernameIsValid(username: String) throws
    func checkIfPasswordIsValid(password: String) throws
    func checkIfNameIsValid(name: String) throws
}

final class UserDataValidationService: UserDataValidationServiceProtocol {

    let authenticationService: AuthenticationServiceProtocol
    let userDataService: UserDataServiceProtocol

    init(authenticationService: AuthenticationServiceProtocol, userDataService: UserDataServiceProtocol) {
        self.authenticationService = authenticationService
        self.userDataService = userDataService
    }

    func checkIfNameIsValid(name: String) throws {
        let nameWithoutWhiteSpaces = name.trimmingExtraWhitespace()

        if nameWithoutWhiteSpaces.isEmpty {
            throw NameValidationError.empty
        }
    }

    func checkIfEmailIsValid(email: String) -> Bool {
        let emailRegEx = "^(?!.*\\.\\.)[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    func checkIfEmailIsAvailable(email: String) async throws -> Bool {
        return try await authenticationService.checkIfEmailIsAvailable(email: email)
    }

    func checkIfUsernameIsAvailable(username: String) async throws -> Bool {
        return try await userDataService.checkIfUsernameIsAvailable(username: username)
    }

    func checkIfUsernameIsValid(username: String) throws {
        guard username.isEmpty != true else {
            throw UsernameValidationError.empty
        }

        // At least 4 characters long
        if username.count < 4 {
            throw UsernameValidationError.tooShort
        }

        // At least one letter
        if username.range(of: #"\p{Alphabetic}+"#, options: .regularExpression) == nil {
            throw UsernameValidationError.noLetters
        }

        // No whitespace characters
        if username.range(of: #"\s+"#, options: .regularExpression) != nil {
            throw UsernameValidationError.includesWhitespaces
        }
    }

    func checkIfPasswordIsValid(password: String) throws {

        // At least 8 characters long
        if password.count < 8 {
            throw PasswordValidationError.tooShort
        }

        // At least one digit
        if password.range(of: #"\d+"#, options: .regularExpression) == nil {
            throw PasswordValidationError.noDigits
        }

        // At least one letter
        if password.range(of: #"\p{Alphabetic}+"#, options: .regularExpression) == nil {
            throw PasswordValidationError.noLetters
        }

        // No whitespace charcters
        if password.range(of: #"\s+"#, options: .regularExpression) != nil {
            throw PasswordValidationError.includesWhitespaces
        }
    }
}

 enum PasswordValidationError: LocalizedError {
    case tooShort
    case noLetters
    case noDigits
    case includesWhitespaces

    var errorDescription: String? {
        switch self {
        case .tooShort:
            return String(localized: "The password should be at least 8 characters long")
        case .noLetters:
            return String(localized: "The password should include at least one letter")
        case .noDigits:
            return String(localized: "The password should include at least one digit")
        case .includesWhitespaces:
            return String(localized: "The password should have no whitespaces")
        }
    }
}

 enum UsernameValidationError: LocalizedError {
    case empty
    case tooShort
    case noLetters
    case includesWhitespaces
    case taken

    var errorDescription: String? {
        switch self {
        case .empty:
            return String(localized: "You must enter a username")
        case .tooShort:
            return String(localized: "The username should be at least 4 characters long")
        case .noLetters:
            return String(localized: "The username should include at least one letter")
        case .includesWhitespaces:
            return String(localized: "The username should have no whitespaces")
        case .taken:
            return String(localized: "This username is already taken")
        }
    }
}

 enum NameValidationError: LocalizedError {
    case empty

    var errorDescription: String? {
        switch self {
        case .empty:
            return String(localized: "You must enter a name")
        }
    }
}
