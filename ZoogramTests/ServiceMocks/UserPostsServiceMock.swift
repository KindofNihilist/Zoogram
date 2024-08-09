//
//  UserPostsServiceMock.swift
//  ZoogramTests
//
//  Created by Artem Dolbiiev on 10.07.2024.
//

import Foundation
@testable import Zoogram

let postFake = UserPost(
    userID: "fakeUserID",
    postID: "fakePostID",
    photoURL: "fakePhotoURL",
    caption: "caption",
    likeCount: 8,
    commentsCount: 8,
    postedDate: Date())

final class UserPostsServiceMock: UserPostsServiceProtocol {

    let posts: [UserPost]

    init(posts: [UserPost]) {
        self.posts = posts
    }

    func insertNewPost(post: Zoogram.UserPost) async throws {
        return
    }

    func deletePost(postID: String, postImageURL: String) async throws {
        return
    }

    func createDeletePostFromFollowersTimelineActions(postID: String) async throws -> [String : Any] {
        return [:]
    }

    func createDeletePostRelatedActivityEventsActions(postID: String) async throws -> [String : Any] {
        return [:]
    }

    func createDeletePostFromBookmarksActions(postID: String) async throws -> [String : Any] {
        return [:]
    }

    func getPost(ofUser user: String, postID: String) async throws -> Zoogram.UserPost {
        return postFake
    }

    func getPostCount(for userID: Zoogram.UserID) async throws -> Zoogram.PostCount {
        return posts.count
    }

    func getPosts(quantity: UInt, for userID: Zoogram.UserID) async throws -> Zoogram.PaginatedItems<Zoogram.UserPost> {
        let postsToReturn = self.posts[0..<Int(quantity)]
        let lastRetrievedItemKey = postsToReturn.last?.postID
        let paginatedItems = PaginatedItems(items: Array(postsToReturn), lastRetrievedItemKey: lastRetrievedItemKey!)
        return paginatedItems
    }

    func getMorePosts(quantity: UInt, after postKey: String, for userID: Zoogram.UserID) async throws -> Zoogram.PaginatedItems<Zoogram.UserPost> {
        let lastPaginatedPostIndex = posts.firstIndex { post in
            post.postID == postKey
        }
        let beginIndex = Int(lastPaginatedPostIndex!) + 1
        let endIndex = Int(lastPaginatedPostIndex!) + Int(quantity)
        let postsToReturn = posts[beginIndex...endIndex]
        let lastRetrievedItemKey = postsToReturn.last?.postID
        let paginatedItems = PaginatedItems(items: Array(postsToReturn), lastRetrievedItemKey: lastRetrievedItemKey!)
        return paginatedItems
    }
}
