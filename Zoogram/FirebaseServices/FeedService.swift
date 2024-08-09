//
//  HomeFeedService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.12.2022.
//

import Foundation
@preconcurrency import FirebaseDatabase

protocol FeedServiceProtocol: Sendable {
    func getFeedPostsCount() async throws -> PostCount
    func getPostsForTimeline(quantity: UInt) async throws -> PaginatedItems<UserPost>
    func getMorePostsForTimeline(quantity: UInt, after lastSeenPostKey: String) async throws -> PaginatedItems<UserPost>
}

final class FeedService: FeedServiceProtocol {

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
        let path = DatabaseKeys.timelines + currentUserID
        let query = databaseRef.child(path).queryOrderedByKey().queryLimited(toLast: quantity)

        do {
            let posts = try await withThrowingTaskGroup(of: (Int, UserPost).self, returning: (LastRetrievedPostKey, [UserPost]).self) { group in
                let data = try await query.getData()

                var retrievedPosts = [UserPost?](repeating: nil, count: Int(data.childrenCount))
                var lastReceivedPostKey = ""

                for (index, snapshotChild) in data.children.reversed().enumerated() {
                    guard let postSnapshot = snapshotChild as? DataSnapshot,
                          let postDictionary = postSnapshot.value as? [String: Sendable]
                    else {
                        throw ServiceError.snapshotCastingError
                    }
                    lastReceivedPostKey = postSnapshot.key

                    group.addTask {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
                            var userPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                            userPost.author = try await UserDataService().getUser(for: userPost.userID)
                            return (index, userPost)
                        } catch {
                            throw error
                        }
                    }
                }

                for try await (index, post) in group {
                    retrievedPosts[index] = post
                }
                let compactMappedPosts = retrievedPosts.compactMap { $0 }
                return (lastReceivedPostKey, compactMappedPosts)
            }
            return PaginatedItems(items: posts.1, lastRetrievedItemKey: posts.0)
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
                    var userPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                    userPost.author = try await UserDataService().getUser(for: userPost.userID)
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
