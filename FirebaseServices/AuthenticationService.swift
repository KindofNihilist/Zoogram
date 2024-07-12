//
//  AuthenticationService.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//
import FirebaseAuth

protocol AuthenticationServiceProtocol: Sendable {
    func createNewUser(email: String, password: String, username: String) async throws -> UserID
    func signInUsing(email: String, password: String) async throws -> ZoogramUser
    func listenToAuthenticationState(completion: @escaping (UserID?) -> Void)
    func resetPassword(email: String) async throws
    func checkIfEmailIsAvailable(email: String) async throws -> Bool
    func getCurrentUserUID() throws -> String
    func signOut() throws
}

final class AuthenticationService: AuthenticationServiceProtocol {

    static let shared = AuthenticationService()

    func createNewUser(email: String, password: String, username: String) async throws -> UserID {
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = username
            try await changeRequest.commitChanges()
            return authResult.user.uid
        } catch {
            throw handleError(error: error)
        }
    }

    func signInUsing(email: String, password: String) async throws -> ZoogramUser {
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            try await Auth.auth().currentUser?.reload()
            let currentUser = try await UserDataService().getUser(for: authResult.user.uid)
            if authResult.user.displayName == nil {
                let changeRequest = authResult.user.createProfileChangeRequest()
                changeRequest.displayName = currentUser.username
                try await changeRequest.commitChanges()
            }
            print("currentUser userID: \(currentUser.userID)")
            return currentUser
        } catch {
            throw handleError(error: error)
        }
    }

    func resetPassword(email: String) async throws {
        let actionSettings = ActionCodeSettings()
        actionSettings.handleCodeInApp = true
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email, actionCodeSettings: actionSettings)
        } catch {
            throw handleError(error: error)
        }
    }

    func checkIfEmailIsAvailable(email: String) async throws -> Bool {
        do {
            let signInMethods = try await Auth.auth().fetchSignInMethods(forEmail: email)
            return signInMethods.isEmpty
        } catch {
            throw handleError(error: error)
        }
    }

    func listenToAuthenticationState(completion: @escaping (UserID?) -> Void) {
        Auth.auth().addStateDidChangeListener { _, user in
            completion(user?.uid)
        }
    }

    func getCurrentUserUID() throws -> String {
        if let userID = Auth.auth().currentUser?.uid {
            return userID
        } else {
            throw ServiceError.authorizationError
        }
    }

    func signOut() throws {
        print("signing out")
        do {
            try Auth.auth().signOut()
        } catch {
            throw handleError(error: error)
        }
    }

    func handleError(error: Error) -> Error {
        let error = error as NSError
        let errorCode = AuthErrorCode.Code(rawValue: error.code)

        switch errorCode {
        case .emailAlreadyInUse:
            return AuthenticationError.emailAlreadyInUse
        case .invalidEmail:
            return AuthenticationError.invalidEmail
        case .weakPassword:
            return AuthenticationError.weakPassword
        case .userDisabled:
            return AuthenticationError.userDisabled
        case .wrongPassword:
            return AuthenticationError.wrongPassword
        case .userNotFound:
            return AuthenticationError.userNotFound
        case .networkError:
            return AuthenticationError.networkError
        default:
            return error
        }
    }
}

enum AuthenticationError: LocalizedError {
    case emailAlreadyInUse
    case invalidEmail
    case weakPassword
    case userDisabled
    case wrongPassword
    case userNotFound
    case networkError

    var errorDescription: String? {
        switch self {
        case .emailAlreadyInUse: return String(localized: "Email is already in use")
        case .invalidEmail: return String(localized: "Invalid email format")
        case .weakPassword: return String(localized: "Weak password")
        case .userDisabled: return String(localized: "The user has been disabled")
        case .wrongPassword: return String(localized: "Wrong password")
        case .userNotFound: return String(localized: "User with this email doesn't exist")
        case .networkError: return String(localized: "No Internet Connection")
        }
    }
}
