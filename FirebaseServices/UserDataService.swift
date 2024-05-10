//
//  UserService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.12.2022.
//

import Foundation
import FirebaseDatabase
import SDWebImage

typealias IsAvailable = Bool
typealias PictureURL = String

protocol UserDataServiceProtocol {
    func observeCurrentUser(with uid: String, completion: @escaping (Result<ZoogramUser, Error>) -> Void)
    func getUser(for userID: UserID) async throws -> ZoogramUser
    func insertNewUserData(with userData: ZoogramUser) async throws
    func searchUserWith(username: String) async throws -> [ZoogramUser]
    func checkIfUsernameIsAvailable(username: String) async throws -> Bool
    func updateUserProfile(with values: [String: Any]) async throws
    func uploadUserProfilePictureForNewlyCreatedaUser(with uid: UserID, profilePic: UIImage) async throws -> URL
    func updateUserProfilePicture(newProfilePic: UIImage) async throws
}

class UserDataService: UserDataServiceProtocol {

    static let shared = UserDataService()

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    func observeCurrentUser(with uid: UserID, completion: @escaping (Result<ZoogramUser, Error>) -> Void) {
        let path = DatabaseKeys.users + uid
        let query = databaseRef.child(path)
        query.observe(.value) { snapshot in
            guard let snapshotDict = snapshot.value as? [String: Any] else {
                completion(.failure(ServiceError.snapshotCastingError))
                return
            }

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: snapshotDict)
                let decodedUser = try JSONDecoder().decode(ZoogramUser.self, from: jsonData)
                ImageService.shared.getImage(for: decodedUser.profilePhotoURL) { result in
                    switch result {
                    case.success(let profilePhoto):
                        decodedUser.setProfilePhoto(profilePhoto)
                        completion(.success(decodedUser))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                completion(.success(decodedUser))
            } catch {
                completion(.failure(ServiceError.jsonParsingError))
            }
        }
    }

    func getUser(for userID: UserID, completion: @escaping (Result<ZoogramUser, Error>) -> Void) {
        let path = DatabaseKeys.users + userID
        let query = databaseRef.child(path)

        query.getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadData))
            } else if let snapshot = snapshot {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: snapshot.value)
                    let decodedUser = try JSONDecoder().decode(ZoogramUser.self, from: jsonData)
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

        do {
            let data = try await databaseRef.child(path).getData()
            let json = try JSONSerialization.data(withJSONObject: data.value as Any)
            let decodedUser = try JSONDecoder().decode(ZoogramUser.self, from: json)
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
        } catch {
            throw ServiceError.couldntUploadUserData
        }
    }

    func searchUserWith(username: String) async throws -> [ZoogramUser] {
        let query = databaseRef.child(DatabaseKeys.users).queryOrdered(byChild: "username").queryStarting(atValue: username).queryEnding(atValue: "\(username)~")

        do {
            let data = try await query.getData()
            var foundUsers = [ZoogramUser]()

            for snapshot in data.children {
                guard let userSnapshot = snapshot as? DataSnapshot,
                      let userDictionary = userSnapshot.value as? [String: Any]
                else {
                    throw ServiceError.snapshotCastingError
                }
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: userDictionary as Any)
                    let decodedUser = try JSONDecoder().decode(ZoogramUser.self, from: jsonData)
                    decodedUser.followStatus = try await FollowSystemService.shared.checkFollowStatus(for: decodedUser.userID)
                    foundUsers.append(decodedUser)
                } catch {
                    throw error
                }
            }
            return foundUsers
        } catch {
            throw ServiceError.couldntCompleteTheSearch
        }
    }

    func checkIfUsernameIsAvailable(username: String) async throws -> Bool {
        let query = databaseRef.child(DatabaseKeys.users).queryOrdered(byChild: "username").queryEqual(toValue: username)

        do {
            let data = try await query.getData()
            return data.exists() ? false : true
        } catch {
            throw ServiceError.couldntLoadData
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
