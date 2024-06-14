//
//  RecentPostsService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.04.2024.
//

import Foundation
@preconcurrency import Firebase

protocol DiscoverPostsServiceProtocol: Sendable {
    func getDiscoverPostsCount() async throws -> PostCount
    func getDiscoverPosts(quantity: UInt) async throws -> PaginatedItems<UserPost>
    func getMoreDiscoverPosts(quantity: UInt, after lastRetrievedPostKey: String) async throws -> PaginatedItems<UserPost>
}

final class DiscoverPostsService: DiscoverPostsServiceProtocol {

    static let shared = DiscoverPostsService()

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    func getDiscoverPostsCount() async throws -> PostCount {
        let query = databaseRef.child("DiscoverPosts/")

        do {
            let data = try await query.getData()
            return Int(data.childrenCount)
        } catch {
            throw ServiceError.couldntLoadPosts
        }
    }

    func getDiscoverPosts(quantity: UInt) async throws -> PaginatedItems<UserPost> {
        var retrievedPosts = [UserPost]()
        var lastRetrievedPostKey: String = ""
        let query = databaseRef.child("DiscoverPosts/").queryOrderedByKey().queryLimited(toLast: quantity)

        do {
            let data = try await query.getData()

            for snapshot in data.children.reversed() {
                guard let postSnapshot = snapshot as? DataSnapshot,
                      let postDict = postSnapshot.value as? [String: Any]
                else {
                    throw ServiceError.snapshotCastingError
                }
                lastRetrievedPostKey = postSnapshot.key

                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: postDict as Any)
                    var post = try JSONDecoder().decode(UserPost.self, from: jsonData)
                    post.author = try await UserDataService().getUser(for: post.userID)
                    retrievedPosts.append(post)
                } catch {
                    throw error
                }
            }
            return PaginatedItems(items: retrievedPosts, lastRetrievedItemKey: lastRetrievedPostKey)
        } catch {
            throw ServiceError.couldntLoadPosts
        }
    }

    func getMoreDiscoverPosts(quantity: UInt, after lastRetrievedPostKey: String) async throws -> PaginatedItems<UserPost> {
        var retrievedPosts = [UserPost]()

        let query = databaseRef.child("DiscoverPosts/").queryOrderedByKey().queryEnding(beforeValue: lastRetrievedPostKey).queryLimited(toLast: quantity)

        do {
            var lastPostKey = ""
            let data = try await query.getData()

            for snapshot in data.children.reversed() {
                guard let postSnapshot = snapshot as? DataSnapshot,
                      let postDict = postSnapshot.value as? [String: Any]
                else {
                    throw ServiceError.snapshotCastingError
                }
                lastPostKey = postSnapshot.key

                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: postDict as Any)
                    var post = try JSONDecoder().decode(UserPost.self, from: jsonData)
                    post.author = try await UserDataService().getUser(for: post.userID)
                    retrievedPosts.append(post)
                } catch {
                    throw error
                }
            }
            return PaginatedItems(items: retrievedPosts, lastRetrievedItemKey: lastPostKey)
        } catch {
            throw ServiceError.couldntLoadPosts
        }
    }
}
