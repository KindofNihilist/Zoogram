//
//  UserProfileDataValidationService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 16.01.2024.
//

import Foundation

protocol UserDataValidationServiceProtocol: AnyObject {
    func checkIfEmailIsAvailable(email: String, completion: @escaping (Result<IsAvailable, Error>) -> Void)
    func checkIfEmailIsValid(email: String) -> Bool
    func checkIfUsernameIsAvailable(username: String, completion: @escaping (Result<IsAvailable, Error>) -> Void)
    func checkIfUsernameIsValid(username: String, completion: @escaping (VoidResultWithErrorDescription) -> Void)
    func checkIfPasswordIsValid(password: String, completion: @escaping (VoidResultWithErrorDescription) -> Void)
    func checkIfNameIsValid(name: String, completion: @escaping (VoidResultWithErrorDescription) -> Void)
}

protocol LocalizableEnum {
    func localizedString() -> String
}

class UserDataValidationService: UserDataValidationServiceProtocol {

    func checkIfNameIsValid(name: String, completion: @escaping (VoidResultWithErrorDescription) -> Void) {
        let nameWithoutWhiteSpaces = name.trimmingExtraWhitespace()

        if nameWithoutWhiteSpaces.isEmpty {
            completion(.failure(String(localized: "Name can't be empty")))
        } else {
            completion(.success)
        }
    }

    func checkIfEmailIsAvailable(email: String, completion: @escaping (Result<IsAvailable, Error>) -> Void) {
        AuthenticationService.shared.checkIfEmailIsAvailable(email: email) { result in
            completion(result)
        }
    }

    func checkIfUsernameIsAvailable(username: String, completion: @escaping (Result<IsAvailable, Error>) -> Void) {
        UserDataService.shared.checkIfUsernameIsAvailable(username: username) { result in
            completion(result)
        }
    }

    func checkIfUsernameIsValid(username: String, completion: @escaping (VoidResultWithErrorDescription) -> Void) {
        guard username.isEmpty != true else {
            let failureText = String(localized: "You must enter a username")
            completion(.failure(failureText))
            return
        }
        var validationErrors = [UsernameValidationError]()

        if username.count < 4 {
            validationErrors.append(.tooShort)
        }

        // At least one letter
        if username.range(of: #"\p{Alphabetic}+"#, options: .regularExpression) == nil {
            validationErrors.append(.noLetters)
        }

        // No whitespace charcters
        if username.range(of: #"\s+"#, options: .regularExpression) != nil {
            validationErrors.append(.includesWhitespaces)
        }

        if validationErrors.isEmpty {
            completion(.success)
        } else {
            let errorDescriptionBeginning = String(localized: "The username should")
            let errorDescription = createValidationErrorDescription(for: validationErrors, withBeginningDescription: errorDescriptionBeginning)
            completion(.failure(errorDescription))
        }
    }

    func checkIfPasswordIsValid(password: String, completion: @escaping (VoidResultWithErrorDescription) -> Void) {
        var validationErrors = [PasswordValidationError]()

        if password.count < 8 {
            validationErrors.append(.tooShort)
        }

        // At least one digit
        if password.range(of: #"\d+"#, options: .regularExpression) == nil {
            validationErrors.append(.noDigits)
        }

        // At least one letter
        if password.range(of: #"\p{Alphabetic}+"#, options: .regularExpression) == nil {
            validationErrors.append(.noLetters)
        }

        // No whitespace charcters
        if password.range(of: #"\s+"#, options: .regularExpression) != nil {
            validationErrors.append(.includesWhitespaces)
        }

        if validationErrors.isEmpty {
            completion(.success)
        } else {
            let errorDescriptionBeginning = String(localized: "The password should")
            let errorDescription = createValidationErrorDescription(for: validationErrors, withBeginningDescription: errorDescriptionBeginning)
            completion(.failure(errorDescription))
        }
    }

    func createValidationErrorDescription<T: LocalizableEnum>(for errors: [T], withBeginningDescription description: String) -> String {
        var errorDescription = description
        let endIndex = errors.endIndex - 1
        let startIndex = errors.startIndex

        for (index, error) in errors.enumerated() {
            if index < endIndex && index > startIndex {
                errorDescription += ","
            } else if index > startIndex && index == endIndex {
                errorDescription += String(localized: " and")
            }
            errorDescription += error.localizedString()
        }
        return errorDescription
    }

    func checkIfEmailIsValid(email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

fileprivate enum PasswordValidationError: LocalizableEnum {
    case tooShort
    case noLetters
    case noDigits
    case includesWhitespaces

    func localizedString() -> String {
        switch self {
        case .tooShort:
            return String(localized: " be at least 8 characters long")
        case .noLetters:
            return String(localized: " include at least one letter")
        case .noDigits:
            return String(localized: " include at least one digit")
        case .includesWhitespaces:
            return String(localized: " have no whitespaces")
        }
    }
}

fileprivate enum UsernameValidationError: LocalizableEnum {
    case tooShort
    case noLetters
    case includesWhitespaces

    func localizedString() -> String {
        switch self {
        case .tooShort:
            return String(localized: " be at least 4 characters long")
        case .noLetters:
            return String(localized: " include at least one letter")
        case .includesWhitespaces:
            return String(localized: " have no whitespaces")
        }
    }
}

