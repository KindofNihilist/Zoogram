//
//  HomeFeedService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.12.2022.
//

import Foundation
import FirebaseDatabase

typealias CompletionBlockWithPosts = (Result<([UserPost], LastRetrievedPostKey), Error>) -> Void

protocol FeedServiceProtocol {
    func getFeedPostsCount(completion: @escaping (Result<PostCount, Error>) -> Void)
    func getPostsForTimeline(quantity: UInt, completion: @escaping CompletionBlockWithPosts)
    func getMorePostsForTimeline(quantity: UInt, after lastSeenPostKey: String, completion: @escaping CompletionBlockWithPosts)
}

class FeedService: FeedServiceProtocol {

    static let shared = FeedService()

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    func getFeedPostsCount(completion: @escaping (Result<PostCount, Error>) -> Void) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }
        let databaseKey = "Timelines/\(currentUserID)/"

        databaseRef.child(databaseKey).getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadPosts))
                return
            } else if let snapshot = snapshot {
                let numberOfFeedPosts = Int(snapshot.childrenCount)
                completion(.success(numberOfFeedPosts))
            } else {
                completion(.failure(ServiceError.couldntLoadPosts))
            }
        }
    }

    func getPostsForTimeline(quantity: UInt, completion: @escaping CompletionBlockWithPosts) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }
        let query = databaseRef.child("Timelines/\(currentUserID)").queryOrderedByKey().queryLimited(toLast: quantity)
        query.getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadPosts))
                return
            } else if let snapshot = snapshot {
                var retrievedPosts = [UserPost]()
                var lastReceivedPostKey = ""
                let dispatchGroup = DispatchGroup()

                for snapshotChild in snapshot.children.reversed() {

                    guard let postSnapshot = snapshotChild as? DataSnapshot,
                          let postDictionary = postSnapshot.value as? [String: Any]
                    else {
                        completion(.failure(ServiceError.snapshotCastingError))
                        break
                    }
                    lastReceivedPostKey = postSnapshot.key
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
                        let userPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                        retrievedPosts.append(userPost)
                    } catch {
                        completion(.failure(ServiceError.jsonParsingError))
                        break
                    }
                }

                retrievedPosts = retrievedPosts.map { userPost in
                    dispatchGroup.enter()
                    UserDataService.shared.getUser(for: userPost.userID) { result in
                        switch result {
                        case .success(let postAuthor):
                            userPost.author = postAuthor
                        case .failure(let error):
                            completion(.failure(ServiceError.couldntLoadPosts))
                            return
                        }
                        dispatchGroup.leave()
                    }
                    return userPost
                }

                dispatchGroup.notify(queue: .main) {
                    completion(.success((retrievedPosts, lastReceivedPostKey)))
                }
            } else {
                completion(.failure(ServiceError.couldntLoadPosts))
            }
        }
    }

    func getMorePostsForTimeline(quantity: UInt, after lastSeenPostKey: String, completion: @escaping CompletionBlockWithPosts) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }
        let query = databaseRef.child("Timelines/\(currentUserID)").queryOrderedByKey().queryEnding(beforeValue: lastSeenPostKey).queryLimited(toLast: quantity)
        query.getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadPosts))
                return
            } else if let snapshot = snapshot {
                var retrievedPosts = [UserPost]()
                var lastReceivedPost = ""
                let dispatchGroup = DispatchGroup()

                for snapshotChild in snapshot.children.reversed() {

                    guard let postSnapshot = snapshotChild as? DataSnapshot,
                          let postDictionary = postSnapshot.value as? [String: Any]
                    else {
                        completion(.failure(ServiceError.snapshotCastingError))
                        return
                    }
                    lastReceivedPost = postSnapshot.key

                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
                        let userPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                        retrievedPosts.append(userPost)
                    } catch {
                        completion(.failure(ServiceError.jsonParsingError))
                        return
                    }
                }

                retrievedPosts = retrievedPosts.map({ userPost in
                    dispatchGroup.enter()
                    UserDataService.shared.getUser(for: userPost.userID) { result in
                        switch result {
                        case .success(let postAuthor):
                            userPost.author = postAuthor
                        case .failure(let error):
                            completion(.failure(ServiceError.couldntLoadPosts))
                            return
                        }
                        dispatchGroup.leave()
                    }
                    return userPost
                })

                dispatchGroup.notify(queue: .main) {
                    completion(.success((retrievedPosts, lastReceivedPost)))
                }
            }
        }
    }
}
