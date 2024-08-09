//
//  AuthenticationServiceMock.swift
//  ZoogramTests
//
//  Created by Artem Dolbiiev on 05.07.2024.
//

import Foundation
@testable import Zoogram

final class AuthenticationServiceMock: AuthenticationServiceProtocol {

    let currentUserID = "LoggedInUserID"

    func createNewUser(email: String, password: String, username: String) async throws -> Zoogram.UserID {
        return currentUserID
    }
    
    func signInUsing(email: String, password: String) async throws -> Zoogram.ZoogramUser {
        return ZoogramUser(currentUserID, isCurrentUser: true)
    }
    
    func listenToAuthenticationState(completion: @escaping (UserID?) -> Void) {
        completion(currentUserID)
    }
    
    func resetPassword(email: String) async throws {
        return
    }
    
    func checkIfEmailIsAvailable(email: String) async throws -> Bool {
        return true
    }
    
    func getCurrentUserUID() throws -> String {
        return currentUserID
    }
    
    func signOut() throws {
        return
    }
}
