//
//  DiscoverViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 21.10.2022.
//

import Foundation

class DiscoverViewModel {

    private var service: any DiscoverServiceProtocol

    var foundUsers = Observable([ZoogramUser]())
    var posts = Observable([PostViewModel]())

    init(service: any DiscoverServiceProtocol) {
        self.service = service
    }

    func isPaginationAllowed() -> Bool {
        return service.hasHitTheEndOfPosts == false && service.isAlreadyPaginating == false
    }

    func getPostsToDiscover() async throws -> [PostViewModel] {
        let retrievedPosts = try await service.getItems()
        if let retrievedPosts = retrievedPosts {
            posts.value = retrievedPosts.map({ post in
                return PostViewModel(post: post)
            })
        }
        return posts.value
    }

    func getMorePostsToDiscover() async throws -> [PostViewModel] {
        let paginatedPosts = try await service.getMoreItems()
        if let paginatedPosts = paginatedPosts {
            let viewModels = paginatedPosts.map({ post in
                return PostViewModel(post: post)
            })
            posts.value.append(contentsOf: viewModels)
            return viewModels
        } else {
            return []
        }
    }

    func searchUser(for input: String) async throws {
        guard input.isEmpty == false else {
            foundUsers.value = []
            return
        }
        foundUsers.value = try await service.searchUserWith(username: input)
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
