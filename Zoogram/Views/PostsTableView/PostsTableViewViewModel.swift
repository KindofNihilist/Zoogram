//
//  PostsTableViewVM.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 30.05.2024.
//

import Foundation

@MainActor
class PostsTableViewViewModel {

    private var service: any PostsNetworking

    var posts = [PostViewModel]()
    var isDisplayingFooter: Bool = false

    init(service: any PostsNetworking, posts: [PostViewModel]) {
        self.service = service
        self.posts = posts
    }

    func getPosts() async throws {
        let receivedItems = try await service.getItems()
        if let unwrappedItems = receivedItems {
            self.posts = unwrappedItems.compactMap({ provider in
                return provider.getPostViewModel()
            })
        }
    }

    func getMorePosts() async throws -> [PostViewModel]? {
        let receivedItems = try await service.getMoreItems()
        if let unwrappedItems = receivedItems {
            let postViewModels = unwrappedItems.compactMap({ provider in
                return provider.getPostViewModel()
            })
            return postViewModels
        } else {
            return nil
        }
    }

    func deletePost(at indexPath: IndexPath) async throws {
        let postViewModel = posts[indexPath.row]
        try await service.deletePost(postModel: postViewModel)
        self.posts.remove(at: indexPath.row)
    }

    func likePost(at indexPath: IndexPath) async throws {
        let postViewModel = posts[indexPath.row]
        try await service.likePost(
            postID: postViewModel.postID,
            likeState: postViewModel.likeState,
            postAuthorID: postViewModel.author.userID)
        posts[indexPath.row].switchLikeState()
    }

    func bookmarkPost(at indexPath: IndexPath) async throws {
        let postViewModel = posts[indexPath.row]
        try await service.bookmarkPost(
            postID: postViewModel.postID,
            authorID: postViewModel.author.userID,
            bookmarkState: postViewModel.bookmarkState)
        self.posts[indexPath.row].switchBookmarkState()
    }

    func isPaginationAllowed() async -> Bool {
        return await service.paginationManager.isPaginationAllowed()
    }

    func hasHitTheEndOfPosts() async -> Bool {
        return await service.checkIfHasHitEndOfItems()
    }
}
