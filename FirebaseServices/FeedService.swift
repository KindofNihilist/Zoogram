//
//  HomeFeedService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.12.2022.
//

import Foundation
import FirebaseDatabase

protocol FeedServiceProtocol {
    func getFeedPostsCount() async throws -> PostCount
    func getPostsForTimeline(quantity: UInt) async throws -> PaginatedItems<UserPost>
    func getMorePostsForTimeline(quantity: UInt, after lastSeenPostKey: String) async throws -> PaginatedItems<UserPost>
}

class FeedService: FeedServiceProtocol {

    static let shared = FeedService()

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    func getFeedPostsCount() async throws -> PostCount {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let databaseKey = "Timelines/\(currentUserID)/"
        let query = databaseRef.child(databaseKey)

        do {
            let data = try await query.getData()
            return Int(data.childrenCount)
        } catch {
            throw ServiceError.couldntLoadPosts
        }
    }

    func getPostsForTimeline(quantity: UInt) async throws -> PaginatedItems<UserPost> {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let query = databaseRef.child("Timelines/\(currentUserID)").queryOrderedByKey().queryLimited(toLast: quantity)

        do {
            let data = try await query.getData()

            var retrievedPosts = [UserPost]()
            var lastReceivedPostKey = ""

            for snapshotChild in data.children.reversed() {
                guard let postSnapshot = snapshotChild as? DataSnapshot,
                      let postDictionary = postSnapshot.value as? [String: Any]
                else {
                    throw ServiceError.snapshotCastingError
                }
                lastReceivedPostKey = postSnapshot.key
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
                    let userPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                    userPost.author = try await UserDataService.shared.getUser(for: userPost.userID)
                    retrievedPosts.append(userPost)
                } catch {
                    throw error
                }
            }
            return PaginatedItems(items: retrievedPosts, lastRetrievedItemKey: lastReceivedPostKey)
        } catch {
            throw ServiceError.couldntLoadPosts
        }
    }

    func getMorePostsForTimeline(quantity: UInt, after lastSeenPostKey: String) async throws -> PaginatedItems<UserPost> {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let databaseKey = "Timelines/\(currentUserID)"
        let query = databaseRef.child(databaseKey).queryOrderedByKey().queryEnding(beforeValue: lastSeenPostKey).queryLimited(toLast: quantity)

        do {
            let data = try await query.getData()

            var retrievedPosts = [UserPost]()
            var lastReceivedPostKey = ""

            for snapshot in data.children.reversed() {
                guard let postSnapshot = snapshot as? DataSnapshot,
                      let postDictionary = postSnapshot.value as? [String: Any]
                else {
                    throw ServiceError.snapshotCastingError
                }
                lastReceivedPostKey = postSnapshot.key

                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
                    let userPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                    userPost.author = try await UserDataService.shared.getUser(for: userPost.userID)
                    retrievedPosts.append(userPost)
                } catch {
                    throw error
                }
            }
            return PaginatedItems(items: retrievedPosts, lastRetrievedItemKey: lastReceivedPostKey)
        } catch {
            throw ServiceError.couldntLoadPosts
        }
    }
}
