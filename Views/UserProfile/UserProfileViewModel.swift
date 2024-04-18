//
//  UserProfileViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.09.2022.
//

import Foundation
import SDWebImage

class UserProfileViewModel {

    private var service: any UserProfileServiceProtocol

    var user: ZoogramUser {
        didSet {
            self.isCurrentUserProfile = user.isCurrentUserProfile
        }
    }

    var isCurrentUserProfile: Bool = false

    var postsCount: Int?
    var followersCount: Int?
    var followedUsersCount: Int?

    var posts: Observable = Observable([PostViewModel]())

    init(service: any UserProfileServiceProtocol, user: ZoogramUser, postsCount: Int, followersCount: Int, followingCount: Int) {
        self.service = service
        self.user = user
        self.postsCount = postsCount
        self.followersCount = followersCount
        self.followedUsersCount = followingCount
        self.isCurrentUserProfile = user.isCurrentUserProfile
    }

    init(service: any UserProfileServiceProtocol) {
        self.service = service
        self.user = ZoogramUser()
        self.postsCount = nil
        self.followersCount = nil
        self.followedUsersCount = nil
        self.isCurrentUserProfile = false
    }

    func isPaginationAllowed() -> Bool {
        return service.hasHitTheEndOfPosts == false && service.isAlreadyPaginating == false
    }

    func getPosts(completion: @escaping (VoidResult) -> Void) {
        service.getItems { posts, error in
            if let error = error {
                completion(.failure(error))
                return
            } else if let posts = posts {
                let postViewModels = posts.compactMap { post in
                    return PostViewModel(post: post)
                }
                self.posts.value = postViewModels
                completion(.success)
            } else {
                completion(.success)
            }
        }
    }

    func getMorePosts(completion: @escaping (Result<[PostViewModel]?, Error>) -> Void) {
        service.getMoreItems { paginatedPosts, error in
            if let error = error {
                completion(.failure(error))
                return
            } else if let paginatedPosts = paginatedPosts {
                let postViewModels = paginatedPosts.compactMap { post in
                    return PostViewModel(post: post)
                }
                self.posts.value.append(contentsOf: postViewModels)
                completion(.success(postViewModels))
            } else {
                completion(.success(nil))
            }
        }
    }

    func getUserProfileData(completion: @escaping(VoidResult) -> Void) {
        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        service.getFollowersCount { result in
            switch result {
            case .success(let followersCount):
                print("got followers count")
                self.followersCount = followersCount
            case .failure(let error):
                completion(.failure(error))
                return
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        service.getFollowingCount { result in
            switch result {
            case .success(let followedUsersCount):
                self.followedUsersCount = followedUsersCount
                print("got following count")
            case .failure(let error):
                completion(.failure(error))
                return
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        service.getNumberOfItems { result in
            switch result {
            case .success(let postsCount):
                self.postsCount = postsCount
                print("got number of items")
            case .failure(let error):
                completion(.failure(error))
                return
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        service.getUserData { result in
            switch result {
            case .success(let retrievedUser):
                print("got current user data")
                self.user = retrievedUser
            case .failure(let error):
                completion(.failure(error))
                return
            }
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            completion(.success)
        }
    }

    func followUser(completion: @escaping (Result<FollowStatus, Error>) -> Void) {
        service.followUser { [weak self] result in
            switch result {
            case .success(let followStatus):
                self?.user.followStatus = followStatus
                completion(.success(followStatus))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func unfollowUser(completion: @escaping (Result<FollowStatus, Error>) -> Void) {
        service.unfollowUser { [weak self] result in
            switch result {
            case .success(let followStatus):
                self?.user.followStatus = followStatus
                completion(.success(followStatus))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func hasHitTheEndOfPosts() -> Bool {
        return service.hasHitTheEndOfPosts
    }

    func hasFinishedPaginating() {
        service.isAlreadyPaginating = false
    }

    func hasLoadedData() -> Bool {
        let hasntRetrievedPosts = service.numberOfRetrievedItems == 0
        let numberOfReceivedItemsIsLessThanRequired = service.numberOfRetrievedItems < service.numberOfItemsToGet
        let hasntRetrievedAllPosts = service.numberOfRetrievedItems < service.numberOfAllItems
        let retrievedLessPostsThanRequired = numberOfReceivedItemsIsLessThanRequired && hasntRetrievedAllPosts

        if hasntRetrievedPosts || retrievedLessPostsThanRequired {
            return false
        } else {
            return true
        }
    }
}
