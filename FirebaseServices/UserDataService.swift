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
    func getUser(for userID: UserID, completion: @escaping (Result<ZoogramUser, Error>) -> Void)
    func observeUser(for userID: UserID, completion: @escaping (Result<ZoogramUser, Error>) -> Void)
    func getLatestUserModel(completion: @escaping (Result<ZoogramUser, Error>) -> Void)
    func getCurrentUser(completion: @escaping (Result<ZoogramUser, Error>) -> Void)
    func insertNewUserData(with userData: ZoogramUser, completion: @escaping (VoidResult) -> Void)
    func searchUserWith(username: String, completion: @escaping (Result<[ZoogramUser], Error>) -> Void)
    func changeHasPostsStatus(hasPostsStatus: Bool, completion: @escaping (VoidResult) -> Void)
    func checkIfUsernameIsAvailable(username: String, completion: @escaping (Result<Bool, Error>) -> Void)
    func updateUserProfile(with values: [String: Any], completion: @escaping (VoidResult) -> Void)
    func uploadUserProfilePictureForNewlyCreatedaUser(with uid: UserID, profilePic: UIImage, completion: @escaping (Result<PictureURL, Error>) -> Void)
    func updateUserProfilePicture(newProfilePic: UIImage, completion: @escaping (VoidResult) -> Void)
}

class UserDataService: UserDataServiceProtocol {

    static let shared = UserDataService()

    var currentUserModel: ZoogramUser?

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    func getLatestUserModel(completion: @escaping (Result<ZoogramUser, Error>) -> Void) {
        if let currentUserModel = currentUserModel {
            completion(.success(currentUserModel))
        } else {
            getCurrentUser { result in
                completion(result)
            }
        }
    }

    func getCurrentUser(completion: @escaping (Result<ZoogramUser, Error>) -> Void) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else {
            return
        }
        getUser(for: currentUserID) { result in
            switch result {
            case .success(let currentUser):
                if let profilePhotoURL = currentUser.profilePhotoURL {
                    ImageService.shared.getImage(for: profilePhotoURL) { result in
                        switch result {
                        case .success(let profilePhoto):
                            currentUser.setProfilePhoto(profilePhoto)
                            self.currentUserModel = currentUser
                            completion(.success(currentUser))
                        case .failure(let error):
                            completion(.failure(ServiceError.couldntLoadUserData))
                        }
                    }
                } else {
                    completion(.success(currentUser))
                }
            case .failure(let error):
                completion(.failure(ServiceError.couldntLoadUserData))
            }
        }
    }

    func getUser(for userID: UserID, completion: @escaping (Result<ZoogramUser, Error>) -> Void) {
        let path = StorageKeys.users.rawValue + userID

        self.databaseRef.child(path).getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadUserData))
                return
            } else if let snapshot = snapshot {

                guard let value = snapshot.value as? [String: Any] else {
                    completion(.failure(ServiceError.snapshotCastingError))
                    return
                }

                do {
                    let json = try JSONSerialization.data(withJSONObject: value as Any)
                    let decodedUser = try JSONDecoder().decode(ZoogramUser.self, from: json)
                    FollowSystemService.shared.checkFollowStatus(for: userID) { result in
                        switch result {
                        case .success(let followStatus):
                            decodedUser.followStatus = followStatus
                            completion(.success(decodedUser))
                            print("successfully retreived user")
                        case .failure(let error):
                            completion(.failure(ServiceError.couldntLoadUserData))
                            return
                        }
                    }
                } catch {
                    completion(.failure(ServiceError.jsonParsingError))
                }
            }
        }
    }

    func observeUser(for userID: UserID, completion: @escaping (Result<ZoogramUser, Error>) -> Void) {
        var path = StorageKeys.users.rawValue + userID

        self.databaseRef.child(path).observe(.value) { snapshot, _ in
            guard let value = snapshot.value as? [String: Any] else {
                completion(.failure(ServiceError.snapshotCastingError))
                return
            }

            do {
                let json = try JSONSerialization.data(withJSONObject: value as Any)
                let decodedUser = try JSONDecoder().decode(ZoogramUser.self, from: json)
                FollowSystemService.shared.checkFollowStatus(for: userID) { result in
                    switch result {
                    case .success(let followStatus):
                        decodedUser.followStatus = followStatus
                        completion(.success(decodedUser))
                    case .failure(let error):
                        completion(.failure(ServiceError.couldntLoadData))
                    }
                }
            } catch {
                completion(.failure(ServiceError.jsonParsingError))
            }
        } withCancel: { error in
            completion(.failure(ServiceError.unexpectedError))
        }
    }

    func insertNewUserData(with userData: ZoogramUser, completion: @escaping (VoidResult) -> Void) {
        let userDictionary = userData.createDictionary()
        let databaseKey = "Users/\(userData.userID)"

        databaseRef.child(databaseKey).setValue(userDictionary) { error, _ in
            if let error = error {
                completion(.failure(ServiceError.couldntUploadUserData))
            } else {
                completion(.success)
            }
        }
    }

    func searchUserWith(username: String, completion: @escaping (Result<[ZoogramUser], Error>) -> Void) {

        let query = databaseRef.child("Users").queryOrdered(byChild: "username").queryStarting(atValue: username).queryEnding(atValue: "\(username)~")

        query.getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntCompleteTheSearch))
                return
            } else if let snapshot = snapshot {

                var foundUsers = [ZoogramUser]()
                let dispatchGroup = DispatchGroup()

                for snapshotChild in snapshot.children {
                    dispatchGroup.enter()
                    guard let userSnapshot = snapshotChild as? DataSnapshot,
                          let userDictionary = userSnapshot.value as? [String: Any]
                    else {
                        completion(.failure(ServiceError.snapshotCastingError))
                        return
                    }
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: userDictionary as Any)
                        let decodedUser = try JSONDecoder().decode(ZoogramUser.self, from: jsonData)
                        FollowSystemService.shared.checkFollowStatus(for: decodedUser.userID) { result in
                            switch result {
                            case .success(let followStatus):
                                decodedUser.followStatus = followStatus
                                foundUsers.append(decodedUser)
                            case . failure(let error):
                                completion(.failure(ServiceError.couldntCompleteTheSearch))
                            }
                            dispatchGroup.leave()
                        }
                    } catch {
                        completion(.failure(ServiceError.jsonParsingError))
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    completion(.success(foundUsers))
                }
            }
        }
    }

    func changeHasPostsStatus(hasPostsStatus: Bool, completion: @escaping (VoidResult) -> Void) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }
        let databaseKey = "Users/\(currentUserID)/hasPosts"

        databaseRef.child(databaseKey).setValue(hasPostsStatus) { error, _ in
            if let error = error {
                completion(.failure(ServiceError.couldntUploadData))
                return
            } else {
                completion(.success)
            }
        }
    }

    typealias IsAvailable = Bool

    func checkIfUsernameIsAvailable(username: String, completion: @escaping (Result<Bool, Error>) -> Void) {

        let query = databaseRef.child("Users").queryOrdered(byChild: "username").queryEqual(toValue: username)

        query.getData { error, snapshot in
            if let error = error {
                completion(.failure(AuthenticationError.networkError))
                return
            } else if let snapshot = snapshot {
                if snapshot.exists() {
                    completion(.success(false))
                } else {
                    completion(.success(true))
                }
            }
        }
    }

    // MARK: User Profile edditing

    func updateUserProfile(with values: [String: Any], completion: @escaping (VoidResult) -> Void) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }
        if !values.isEmpty {
            databaseRef.child("Users/\(currentUserID)").updateChildValues(values) { error, _ in
                if let error = error {
                    completion(.failure(ServiceError.couldntUploadUserData))
                } else {
                    completion(.success)
                }
            }
        } else {
            completion(.success)
        }
    }

    func uploadUserProfilePictureForNewlyCreatedaUser(with uid: UserID, profilePic: UIImage, completion: @escaping (Result<PictureURL, Error>) -> Void) {
        StorageManager.shared.uploadUserProfilePhoto(for: uid, with: profilePic, fileName: "\(uid)_ProfilePicture.png") { result in
            switch result {
            case .success(let pictureURL):
                completion(.success(pictureURL.absoluteString))
            case .failure(let error):
                completion(.failure(ServiceError.couldntUploadData))
            }
        }
    }

    func updateUserProfilePicture(newProfilePic: UIImage, completion: @escaping (VoidResult) -> Void = {_ in}) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }
        let fileName = "\(currentUserID)_ProfilePicture.png"

        StorageManager.shared.uploadUserProfilePhoto(for: currentUserID, with: newProfilePic, fileName: fileName) { [weak self] result in
            switch result {
            case .success(let pictureURL):
                self?.databaseRef.child("Users/\(currentUserID)").updateChildValues(["profilePhotoURL": pictureURL.absoluteString]) { error, _ in
                    if let error = error {
                        completion(.failure(ServiceError.couldntUploadData))
                    } else {
                        completion(.success)
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
