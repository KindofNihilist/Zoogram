//
//  FollowListViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 02.11.2022.
//

import Foundation

class FollowListViewModel {

    let service: FollowListServiceProtocol

    let isUserProfile: Bool

    var userList = [ZoogramUser]()

    init(service: FollowListServiceProtocol, isUserProfile: Bool) {
        self.service = service
        self.isUserProfile = isUserProfile
    }

    func getUserList(completion: @escaping (VoidResult) -> Void) {
        service.getUserList { result in
            switch result {
            case .success(let userList):
                self.userList = userList
                completion(.success)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func followUser(uid: String, completion: @escaping (Result<FollowStatus, Error>) -> Void) {
        service.followUser(uid: uid) { result in
            completion(result)
        }
    }

    func unfollowUser(uid: String, completion: @escaping (Result<FollowStatus, Error>) -> Void) {
        service.unfollowUser(uid: uid) { result in
            completion(result)
        }
    }

    func removeUserFollowingMe(uid: String, completion: @escaping (VoidResult) -> Void) {
        service.removeUserFollowingMe(uid: uid) { result in
            completion(result)
        }
    }

    func undoUserRemoval(uid: String, completion: @escaping (VoidResult) -> Void) {
        service.undoUserRemoval(uid: uid) { result in
            completion(result)
        }
    }
}
