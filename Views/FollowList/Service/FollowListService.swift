//
//  FollowListService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 29.01.2024.
//

import Foundation
import SDWebImage

protocol FollowListServiceProtocol {
    var followSystemService: FollowSystemProtocol { get }
    func getUserList(completion: @escaping (Result<[ZoogramUser], Error>) -> Void)
    func followUser(uid: String, completion: @escaping (Result<FollowStatus, Error>) -> Void)
    func unfollowUser(uid: String, completion: @escaping (Result<FollowStatus, Error>) -> Void)
    func removeUserFollowingMe(uid: String, completion: @escaping (VoidResult) -> Void)
    func undoUserRemoval(uid: String, completion: @escaping (VoidResult) -> Void)
}

class FollowedListService: ImageService, FollowListServiceProtocol {

    var followSystemService: FollowSystemProtocol

    let userID: String

    init(for userID: UserID, followSystemService: FollowSystemProtocol) {
        self.userID = userID
        self.followSystemService = followSystemService
    }

    func getUserList(completion: @escaping (Result<[ZoogramUser], Error>) -> Void) {
        let dispatchGroup = DispatchGroup()
        followSystemService.getFollowing(for: userID) { result in
            print("got result for followers")
            switch result {
            case .success(let followedUsers):
                for user in followedUsers {
                    if let profilePhotoURL = user.profilePhotoURL {
                        dispatchGroup.enter()
                        self.getImage(for: profilePhotoURL) { result in
                            switch result {
                            case .success(let image):
                                user.setProfilePhoto(image)
                            case .failure(let error):
                                completion(.failure(error))
                                break
                            }
                            dispatchGroup.leave()
                        }
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    completion(.success(followedUsers))
                }

            case .failure(let error):
                completion(.failure(error))
            }

        }
    }

    func followUser(uid: String, completion: @escaping (Result<FollowStatus, Error>) -> Void) {
        followSystemService.followUser(uid: uid) { result in
            completion(result)
        }
    }

    func unfollowUser(uid: String, completion: @escaping (Result<FollowStatus, Error>) -> Void) {
        followSystemService.unfollowUser(uid: uid) { result in
            completion(result)
        }
    }

    func removeUserFollowingMe(uid: String, completion: @escaping (VoidResult) -> Void) {
        followSystemService.forcefullyRemoveFollower(uid: uid) { result in
            completion(result)
        }
    }

    func undoUserRemoval(uid: String, completion: @escaping (VoidResult) -> Void) {
        followSystemService.undoForcefullRemoval(ofUser: uid) { result in
            completion(result)
        }
    }
}

class FollowersListService: FollowedListService {
    override func getUserList(completion: @escaping (Result<[ZoogramUser], Error>) -> Void) {
        let dispatchGroup = DispatchGroup()
        followSystemService.getFollowers(for: userID) { result in
            switch result {
            case .success(let followers):
                for user in followers {
                    if let profilePhotoURL = user.profilePhotoURL {
                        dispatchGroup.enter()
                        self.getImage(for: profilePhotoURL) { result in
                            switch result {
                            case .success(let image):
                                user.setProfilePhoto(image)
                            case .failure(let error):
                                completion(.failure(error))
                            }
                            dispatchGroup.leave()
                        }
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    completion(.success(followers))
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
