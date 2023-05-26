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

        databaseRef.child("Timelines/\(currentUserID)").queryOrderedByKey().queryLimited(toLast: 12).observeSingleEvent(of: .value) { snapshot in

            var retrievedPosts = [UserPost]()
            var lastReceivedPost = ""
            let dispatchGroup = DispatchGroup()

            for (index, snapshotChild) in snapshot.children.enumerated().reversed() {

                guard let postSnapshot = snapshotChild as? DataSnapshot,
                      let postDictionary = postSnapshot.value as? [String : Any]
                else {
                    print("Error while creating post dictionary from snapshot")
                    return
                }
                dispatchGroup.enter()
                lastReceivedPost = postSnapshot.key
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
                    let userPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                    retrievedPosts.append(userPost)
                    UserService.shared.getUser(for: userPost.userID) { postAuthor in
                        retrievedPosts[index].author = postAuthor
                        dispatchGroup.leave()
                    }
                } catch {
                    print("Couldn't create post object from dictionary")
                }
            }

            dispatchGroup.notify(queue: .main) {
                completion(retrievedPosts, lastReceivedPost)
            }
        }
    }

    func getMorePostsForTimeline(after lastSeenPostKey: String, completion: @escaping CompletionBlockWithPosts) {

        let currentUserID = AuthenticationManager.shared.getCurrentUserUID()

        databaseRef.child("Timelines/\(currentUserID)").queryOrderedByKey().queryEnding(beforeValue: lastSeenPostKey).queryLimited(toLast: 12).observeSingleEvent(of: .value) { snapshot in

            var retrievedPosts = [UserPost]()
            var lastReceivedPost = ""
            let dispatchGroup = DispatchGroup()

            for (index, snapshotChild) in snapshot.children.enumerated().reversed() {

                guard let postSnapshot = snapshotChild as? DataSnapshot,
                      let postDictionary = postSnapshot.value as? [String : Any]
                else {
                    print("Error while creating post dictionary from snapshot")
                    return
                }
                dispatchGroup.enter()
                lastReceivedPost = postSnapshot.key

                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
                    let userPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                    retrievedPosts.append(userPost)
                    UserService.shared.getUser(for: userPost.userID) { postAuthor in
                        retrievedPosts[index].author = postAuthor
                        dispatchGroup.leave()
                    }

                } catch {
                    print("Couldn't create post object from dictionary")
                }
            }

            dispatchGroup.notify(queue: .main) {
                completion(retrievedPosts, lastReceivedPost)
            }
        }
    }

}
