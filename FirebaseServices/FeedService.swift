//
//  HomeFeedService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.12.2022.
//

import Foundation
import FirebaseDatabase

typealias CompletionBlockWithPosts = ([UserPost], LastRetrievedPostKey) -> Void

class FeedService {

    static let shared = FeedService()

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    func getPostsForTimeline(completion: @escaping CompletionBlockWithPosts) {

        let currentUserID = AuthenticationManager.shared.getCurrentUserUID()
        print("inside getPosts for timeline")

        databaseRef.child("Timelines/\(currentUserID)").queryOrderedByKey().queryLimited(toLast: 6).observeSingleEvent(of: .value) { snapshot in

            var retrievedPosts = [UserPost]()
            var lastReceivedPost = ""
            let dispatchGroup = DispatchGroup()

            for snapshotChild in snapshot.children.reversed() {

                guard let postSnapshot = snapshotChild as? DataSnapshot,
                      let postDictionary = postSnapshot.value as? [String: Any]
                else {
                    print("Error while creating post dictionary from snapshot")
                    return
                }
                lastReceivedPost = postSnapshot.key
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
                    let userPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                    retrievedPosts.append(userPost)
                } catch {
                    print("Couldn't create post object from dictionary")
                }
            }

            retrievedPosts = retrievedPosts.map { userPost in
                dispatchGroup.enter()
                UserService.shared.getUser(for: userPost.userID) { postAuthor in
                    userPost.author = postAuthor
                    dispatchGroup.leave()
                }
                return userPost
            }

            dispatchGroup.notify(queue: .main) {
                completion(retrievedPosts, lastReceivedPost)
            }
        }
    }

    func getMorePostsForTimeline(after lastSeenPostKey: String, completion: @escaping CompletionBlockWithPosts) {

        let currentUserID = AuthenticationManager.shared.getCurrentUserUID()

        databaseRef.child("Timelines/\(currentUserID)").queryOrderedByKey().queryEnding(beforeValue: lastSeenPostKey).queryLimited(toLast: 6).observeSingleEvent(of: .value) { snapshot in

            var retrievedPosts = [UserPost]()
            var lastReceivedPost = ""
            let dispatchGroup = DispatchGroup()

            for snapshotChild in snapshot.children.reversed() {

                guard let postSnapshot = snapshotChild as? DataSnapshot,
                      let postDictionary = postSnapshot.value as? [String: Any]
                else {
                    print("Error while creating post dictionary from snapshot")
                    return
                }
                lastReceivedPost = postSnapshot.key

                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
                    let userPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                    retrievedPosts.append(userPost)
                } catch {
                    print("Couldn't create post object from dictionary")
                }
            }

            retrievedPosts = retrievedPosts.map({ userPost in
                dispatchGroup.enter()
                UserService.shared.getUser(for: userPost.userID) { postAuthor in
                    userPost.author = postAuthor
                    dispatchGroup.leave()
                }
                return userPost
            })

            dispatchGroup.notify(queue: .main) {
                completion(retrievedPosts, lastReceivedPost)
            }
        }
    }

}
