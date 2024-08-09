//
//  UserService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.12.2022.
//

import Foundation
@preconcurrency import FirebaseDatabase

typealias IsAvailable = Bool
typealias PictureURL = String

protocol UserDataServiceProtocol: Sendable {
    func observeUser(with uid: String, completion: @escaping (Result<ZoogramUser, Error>) -> Void)
    func getUser(for userID: UserID) async throws -> ZoogramUser
    func insertNewUserData(with userData: ZoogramUser) async throws
    func checkIfUsernameIsAvailable(username: String) async throws -> Bool
    func updateUserProfile(with values: [String: Any]) async throws
    func uploadUserProfilePictureForNewlyCreatedaUser(with uid: UserID, profilePic: UIImage) async throws -> URL
    func updateUserProfilePicture(newProfilePic: UIImage) async throws
}

final class UserDataService: UserDataServiceProtocol {

    static let shared = UserDataService()

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    func observeUser(with uid: UserID, completion: @escaping (Result<ZoogramUser, Error>) -> Void) {
        let path = DatabaseKeys.users + uid
        let query = databaseRef.child(path)
        query.observe(.value) { snapshot in
            guard let snapshotDict = snapshot.value as? [String: Any] else {
                completion(.failure(ServiceError.snapshotCastingError))
                return
            }

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: snapshotDict)
                var decodedUser = try JSONDecoder().decode(ZoogramUser.self, from: jsonData)
                ImageService.shared.getImage(for: decodedUser.profilePhotoURL) { result in
                    switch result {
                    case.success(let profilePhoto):
                        decodedUser.setProfilePhoto(profilePhoto)
                        completion(.success(decodedUser))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            } catch {
                completion(.failure(ServiceError.jsonParsingError))
            }
        }
    }

    func getUser(for userID: UserID, completion: @escaping (Result<ZoogramUser, Error>) -> Void) {
        let path = DatabaseKeys.users + userID
        let query = databaseRef.child(path)

        query.getData { error, snapshot in
            if error != nil {
                completion(.failure(ServiceError.couldntLoadData))
            } else if let snapshot = snapshot {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: snapshot.value as Any)
                    var decodedUser = try JSONDecoder().decode(ZoogramUser.self, from: jsonData)
                    ImageService.shared.getImage(for: decodedUser.profilePhotoURL) { result in
                        switch result {
                        case.success(let profilePhoto):
                            decodedUser.setProfilePhoto(profilePhoto)
                            completion(.success(decodedUser))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                } catch {
                    completion(.failure(ServiceError.jsonParsingError))
                }
            } else {
                completion(.failure(ServiceError.unexpectedError))
            }
        }
    }

    func getUser(for userID: UserID) async throws -> ZoogramUser {
        let path = DatabaseKeys.users + userID
        let databaseReference = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

        do {
            let dataSnapshot = try await databaseReference.child("\(path)").getData()
            var decodedUser = try dataSnapshot.data(as: ZoogramUser.self)
            decodedUser.followStatus = try await FollowSystemService.shared.checkFollowStatus(for: userID)
            return decodedUser
        } catch {
            throw ServiceError.couldntLoadUserData
        }
    }

    func insertNewUserData(with userData: ZoogramUser) async throws {
        let userDictionary = userData.createDictionary()
        let databaseKey = DatabaseKeys.users + userData.userID

        do {
            try await databaseRef.child(databaseKey).setValue(userDictionary)
            try await insertLowercasedUsername(username: userData.username, userID: userData.userID)
        } catch {
            throw ServiceError.couldntUploadUserData
        }
    }

    func insertLowercasedUsername(username: String, userID: String) async throws {
        let lowercasedUsername = username.lowercased()
        var dictionary = [String: String]()
        dictionary["userID"] = userID
        dictionary["username"] = lowercasedUsername
        let lowercasedUsernamesRef = databaseRef.child(DatabaseKeys.usernames).child(userID)
        try await lowercasedUsernamesRef.setValue(dictionary)
    }

    func checkIfUsernameIsAvailable(username: String) async throws -> Bool {
        let query = databaseRef.child(DatabaseKeys.usernames).queryOrdered(byChild: "username").queryEqual(toValue: username)

        do {
            let data = try await query.getData()
            return data.exists() ? false : true
        } catch {
            throw ServiceError.unexpectedError
        }
    }

    // MARK: User Profile edditing
    func updateUserProfile(with values: [String: Any]) async throws {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let path = DatabaseKeys.users + currentUserID
        if values.isEmpty == false {
            let query = databaseRef.child(path)
            do {
                try await query.updateChildValues(values)
            } catch {
                throw ServiceError.couldntUploadUserData
            }
        }
        if let username = values["username"] as? String {
            try await self.insertLowercasedUsername(username: username, userID: currentUserID)
        }
    }

    func uploadUserProfilePictureForNewlyCreatedaUser(with uid: UserID, profilePic: UIImage) async throws -> URL {
        let fileName = "\(uid)_ProfilePicture.png"

        do {
            let uploadedPictureURL = try await StorageManager.shared.uploadUserProfilePhoto(for: uid, with: profilePic, fileName: fileName)
            return uploadedPictureURL
        } catch {
            throw ServiceError.couldntUploadUserData
        }
    }

    func updateUserProfilePicture(newProfilePic: UIImage) async throws {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let fileName = "\(currentUserID)_ProfilePicture.png"

        do {
            let uploadedPictureURL = try await StorageManager.shared.uploadUserProfilePhoto(for: currentUserID, with: newProfilePic, fileName: fileName)
            let path = DatabaseKeys.users + currentUserID
            let query = databaseRef.child(path)
            try await query.updateChildValues(["profilePhotoURL": uploadedPictureURL.absoluteString])
        } catch {
            throw ServiceError.couldntUploadUserData
        }
    }
}
