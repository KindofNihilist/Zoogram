//
//  RecentPostsService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.04.2024.
//

import Foundation
import Firebase

protocol DiscoverPostsServiceProtocol {
    func getDiscoverPostsCount(completion: @escaping (Result<PostCount, Error>) -> Void)
    func getDiscoverPosts(quantity: UInt, completion: @escaping CompletionBlockWithPosts)
    func getMoreDiscoverPosts(quantity: UInt, after lastRetrievedPostKey: LastRetrievedPostKey, completion: @escaping CompletionBlockWithPosts)
}

class DiscoverPostsService: DiscoverPostsServiceProtocol {

    static let shared = DiscoverPostsService()

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    func getDiscoverPostsCount(completion: @escaping (Result<PostCount, Error>) -> Void) {
        let query = databaseRef.child("DiscoverPosts/")
        query.getData { error, snapshot in
            if let error = error {
                completion(.failure(error))
                return
            } else if let snapshot = snapshot {
                let numberOfRecentPosts = Int(snapshot.childrenCount)
                completion(.success(numberOfRecentPosts))
            } else {
                completion(.failure(ServiceError.couldntLoadPosts))
            }
        }
    }

    func getDiscoverPosts(quantity: UInt, completion: @escaping CompletionBlockWithPosts) {
        let query = databaseRef.child("DiscoverPosts/").queryOrderedByKey().queryLimited(toLast: quantity)
        query.getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadPosts))
            } else if let snapshot = snapshot {
                var retrievedPosts = [UserPost]()
                var lastRetrievedPostKey: String = ""
                let dispatchGroup = DispatchGroup()

                for snapshotChild in snapshot.children.reversed() {
                    guard let postSnapshot = snapshotChild as? DataSnapshot,
                          let postDict = postSnapshot.value as? [String: Any]
                    else {
                        completion(.failure(ServiceError.snapshotCastingError))
                        break
                    }
                    lastRetrievedPostKey = postSnapshot.key

                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: postDict as Any)
                        let post = try JSONDecoder().decode(UserPost.self, from: jsonData)
                        retrievedPosts.append(post)
                    } catch {
                        completion(.failure(ServiceError.jsonParsingError))
                        break
                    }
                }

                retrievedPosts = retrievedPosts.map({ post in
                    dispatchGroup.enter()
                    UserDataService.shared.getUser(for: post.userID ) { result in
                        switch result {
                        case .success(let user):
                            post.author = user
                        case.failure(_):
                            completion(.failure(ServiceError.couldntLoadPosts))
                            return
                        }
                        dispatchGroup.leave()
                    }
                    return post
                })

                dispatchGroup.notify(queue: .main) {
                    completion(.success((retrievedPosts, lastRetrievedPostKey)))
                }
            } else {
                completion(.failure(ServiceError.couldntLoadPosts))
            }
        }
    }

    func getMoreDiscoverPosts(quantity: UInt, after lastRetrievedPostKey: LastRetrievedPostKey, completion: @escaping CompletionBlockWithPosts) {
        let query = databaseRef.child("DiscoverPosts/").queryOrderedByKey().queryEnding(beforeValue: lastRetrievedPostKey).queryLimited(toLast: quantity)
        query.getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadPosts))
                return
            } else if let snapshot = snapshot {
                var retrievedPosts = [UserPost]()
                var lastRetrievedPostKey = ""
                var dispatchGroup = DispatchGroup()

                for snapshotChild in snapshot.children.reversed() {
                    guard let postSnapshot = snapshotChild as? DataSnapshot,
                          let postDict = postSnapshot.value as? [String: Any]
                    else {
                        completion(.failure(ServiceError.snapshotCastingError))
                        break
                    }
                    lastRetrievedPostKey = postSnapshot.key

                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: postDict as Any)
                        let post = try JSONDecoder().decode(UserPost.self, from: jsonData)
                        retrievedPosts.append(post)
                    } catch {
                        completion(.failure(ServiceError.jsonParsingError))
                        break
                    }
                }

                retrievedPosts = retrievedPosts.map({ post in
                    dispatchGroup.enter()
                    UserDataService.shared.getUser(for: post.userID) { result in
                        switch result {
                        case .success(let user):
                            post.author = user
                        case .failure(let error):
                            completion(.failure(ServiceError.couldntLoadPosts))
                            break
                        }
                        dispatchGroup.leave()
                    }
                    return post
                })

                dispatchGroup.notify(queue: .main) {
                    completion(.success((retrievedPosts, lastRetrievedPostKey)))
                }
            } else {
                completion(.failure(ServiceError.couldntLoadPosts))
            }
        }
    }
}

