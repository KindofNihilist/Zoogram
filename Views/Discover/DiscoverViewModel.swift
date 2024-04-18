//
//  DiscoverViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 21.10.2022.
//

import Foundation

class DiscoverViewModel {

    private var service: any DiscoverServiceProtocol

    var foundUsers = [ZoogramUser]()
    var posts = Observable([PostViewModel]())

    init(service: any DiscoverServiceProtocol) {
        self.service = service
    }

    func isPaginationAllowed() -> Bool {
        return service.hasHitTheEndOfPosts == false && service.isAlreadyPaginating == false
    }

    func getPostsToDiscover(completion: @escaping (VoidResult) -> Void) {
        service.getItems { posts, error in
            if let error = error {
                completion(.failure(error))
            } else if let posts = posts {
                self.posts.value = posts.map({ post in
                    return PostViewModel(post: post)
                })
                completion(.success)
            } else {
                completion(.success)
            }
        }
    }

    func getMorePostsToDiscover(completion: @escaping (Result<[PostViewModel]?, Error>) -> Void) {
        service.getMoreItems { posts, error in
            if let error = error {
                completion(.failure(error))
            } else if let posts = posts {
                let postViewModels = posts.map { post in
                    return PostViewModel(post: post)
                }
                self.posts.value.append(contentsOf: postViewModels)
                completion(.success(postViewModels))
            } else {
                completion(.success(nil))
            }
        }
    }

    func searchUser(for input: String, completion: @escaping (VoidResult) -> Void) {
        guard input.isEmpty == false else {
            foundUsers = []
            completion(.success)
            return
        }
        service.searchUserWith(username: input) { [weak self] result in
            switch result {
            case .success(let users):
                self?.foundUsers = users
                completion(.success)
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
