//
//  PostsService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 08.04.2023.
//

import Foundation
import SDWebImage

protocol PostsNetworking<T>: PostActionsService, Paginatable, AdditionalPostDataSource where T: PostViewModelProvider {}

protocol PostActionsService {
    func likePost(postID: String, likeState: LikeState, postAuthorID: String) async throws -> LikeState
    func deletePost(postModel: PostViewModel) async throws
    func bookmarkPost(postID: String, authorID: String, bookmarkState: BookmarkState) async throws -> BookmarkState
}

protocol AdditionalPostDataSource: ImageService {
    func getAdditionalPostDataFor(postsOfMultipleUsers: [UserPost]) async throws -> [UserPost]
    func getAdditionalPostDataFor(postsOfSingleUser: [UserPost]) async throws -> [UserPost]
}

struct PaginatedItems<T: PostViewModelProvider> {
    var items: [T]
    var lastRetrievedItemKey: String
}

protocol Paginatable { 
    associatedtype T = PostViewModelProvider
    var numberOfItemsToGet: UInt {get set}
    var numberOfAllItems: UInt {get set}
    var numberOfRetrievedItems: UInt {get set}
    var lastReceivedItemKey: String {get set}
    var isAlreadyPaginating: Bool {get set}
    var hasHitTheEndOfPosts: Bool {get set}
    func getNumberOfItems() async throws -> Int
    func getItems() async throws -> [T]?
    func getMoreItems() async throws -> [T]?
}

protocol PostViewModelProvider {
    func getPostViewModel() -> PostViewModel?
}

extension AdditionalPostDataSource {

    func getAdditionalPostDataFor(postsOfMultipleUsers: [UserPost]) async throws -> [UserPost] {
        guard postsOfMultipleUsers.isEmpty != true else {
            return []
        }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for post in postsOfMultipleUsers {
                do {
                    let postID = post.postID

                    async let profilePhoto = getImage(for: post.author.profilePhotoURL)
                    async let postPhoto = getImage(for: post.photoURL)
                    async let likesCount = LikeSystemService.shared.getLikesCountForPost(id: postID)
                    async let commentsCount = CommentSystemService.shared.getCommentsCountForPost(postID: postID)
                    async let bookmarkState = BookmarksSystemService.shared.checkIfBookmarked(postID: postID)
                    async let likeState = LikeSystemService.shared.checkIfPostIsLiked(postID: postID)

                    post.author.setProfilePhoto(try await profilePhoto)
                    post.image = try await postPhoto
                    post.likesCount = try await likesCount
                    post.commentsCount = try await commentsCount
                    post.bookmarkState = try await bookmarkState
                    post.likeState = try await likeState
                } catch {
                    throw error
                }
            }
        }
        return postsOfMultipleUsers
    }

    func getAdditionalPostDataFor(postsOfSingleUser: [UserPost]) async throws -> [UserPost] {
        guard let postsAuthor = postsOfSingleUser.first?.author, 
                postsOfSingleUser.isEmpty != true else {
            return []
        }

        if let profilePhotoURL = postsAuthor.profilePhotoURL {
            postsAuthor.setProfilePhoto(try await getImage(for: profilePhotoURL))
        }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for post in postsOfSingleUser {
                do {
                    let postID = post.postID
                    async let postPhoto = getImage(for: post.photoURL)
                    async let likesCount = LikeSystemService.shared.getLikesCountForPost(id: postID)
                    async let commentsCount = CommentSystemService.shared.getCommentsCountForPost(postID: postID)
                    async let bookmarkState = BookmarksSystemService.shared.checkIfBookmarked(postID: postID)
                    async let likeState = LikeSystemService.shared.checkIfPostIsLiked(postID: postID)

                    post.image = try await postPhoto
                    post.likesCount = try await likesCount
                    post.commentsCount = try await commentsCount
                    post.bookmarkState = try await bookmarkState
                    post.likeState = try await likeState
                } catch {
                    throw error
                }
            }
        }

        return postsOfSingleUser.map { post in
            post.author = postsAuthor
            return post
        }
    }
}
