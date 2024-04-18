//
//  AuthenticationService.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//
import FirebaseAuth

protocol AuthenticationProtocol {
    func createNewUser(email: String, password: String, username: String, completion: @escaping (Result<UserID, Error>) -> Void)
    func signInUsing(email: String, password: String, completion: @escaping (Result<ZoogramUser, Error>) -> Void)
    func listenToAuthenticationState(completion: @escaping (User?) -> Void)
    func resetPassword(email: String, completion: @escaping (VoidResult) -> Void)
    func checkIfEmailIsAvailable(email: String, completion: @escaping (Result<IsAvailable, Error>) -> Void)
    func getCurrentUserUID() -> String?
    func signOut(completion: (VoidResult) -> Void)
}

class AuthenticationService: AuthenticationProtocol {

    static let shared = AuthenticationService()

    func getCurrentUserBasicModel() -> ZoogramUser? {
        guard let currentUser = Auth.auth().currentUser else {
            return nil
        }
        let userModel = ZoogramUser(
            userID: currentUser.uid,
            profilePhotoURL: "",
            email: currentUser.email!,
            username: currentUser.displayName ?? "",
            name: "",
            birthday: "",
            gender: "",
            posts: 0,
            joinDate: 0.0)
        return userModel
    }

    func createNewUser(email: String, password: String, username: String, completion: @escaping (Result<UserID, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                let handledError = self.handleError(error: error)
                completion(.failure(handledError))
            } else {
                guard let authResult = authResult else { return }
                let changeRequest = authResult.user.createProfileChangeRequest()
                changeRequest.displayName = username
                changeRequest.commitChanges()
                completion(.success(authResult.user.uid))
            }
        }
    }

    func signInUsing(email: String, password: String, completion: @escaping (Result<ZoogramUser, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                let handledError = self.handleError(error: error)
                completion(.failure(handledError))
            } else {
                Auth.auth().currentUser?.reload(completion: { error in
                    if let error = error {
                        let handledError = self.handleError(error: error)
                        completion(.failure(handledError))
                    }

                    UserDataService.shared.getCurrentUser { result in
                        switch result {
                        case .success(let currentUser):
                            if authResult?.user.displayName == nil {
                                let changeRequest = authResult?.user.createProfileChangeRequest()
                                changeRequest?.displayName = currentUser.username
                                changeRequest?.commitChanges()
                            }
                            completion(.success(currentUser))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                })
            }
        }
    }

    func resetPassword(email: String, completion: @escaping (VoidResult) -> Void) {
        let actionSettings = ActionCodeSettings()
        actionSettings.handleCodeInApp = true
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                let handledError = self.handleError(error: error)
                completion(.failure(handledError))
            } else {
                completion(.success)
            }
        }
    }

    func checkIfEmailIsAvailable(email: String, completion: @escaping (Result<IsAvailable, Error>) -> Void) {
        Auth.auth().fetchSignInMethods(forEmail: email) { signInMethods, error in
            if let error = error {
                let handledError = self.handleError(error: error)
                completion(.failure(handledError))
            } else {
                completion(.success(signInMethods == nil))
            }
        }
    }

    func listenToAuthenticationState(completion: @escaping (User?) -> Void) {
        Auth.auth().addStateDidChangeListener { auth, user in
            completion(user)
        }
    }

    func getCurrentUserUID() -> String? {
        return Auth.auth().currentUser?.uid
    }

    func signOut(completion: (VoidResult) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(.success)
        } catch {
            let handledError = self.handleError(error: error)
            completion(.failure(handledError))
        }
    }

    func handleError(error: Error) -> Error {
        guard let error = error as? NSError else { return error }
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
