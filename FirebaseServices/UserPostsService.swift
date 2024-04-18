//
//  NewPostService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.12.2022.
//

import Foundation
import FirebaseDatabase

typealias PostCount = Int
typealias PhotoURLString = String

protocol UserPostsServiceProtocol {
    func insertNewPost(post: UserPost, completion: @escaping (VoidResult) -> Void)
    func deletePost(postID: String, postImageURL: String, completion: @escaping (VoidResult) -> Void)
    func deletePostFromFollowersTimeline(postID: String, completion: @escaping (VoidResult) -> Void)
    func getPost(ofUser user: String, postID: String, completion: @escaping (Result<UserPost, Error>) -> Void)
    func getPostCount(for userID: String, completion: @escaping (Result<PostCount, Error>) -> Void)
    func getPosts(quantity: UInt, for userID: String, completion: @escaping CompletionBlockWithPosts)
    func getMorePosts(quantity: UInt, after postKey: String, for userID: String, completion: @escaping CompletionBlockWithPosts)
}

class UserPostsService: UserPostsServiceProtocol {

    static let shared = UserPostsService()

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    func createPostUID() -> String {
        return databaseRef.child("Posts").childByAutoId().key!
    }

    // MARK: Create post

    // By using multipath batch updates this method creates new post entry for user, fans it out to every follower timeline and changes hasPosts bool status all in one write. So it either succeeds or fails, no midpoint results.

    func insertNewPost(post: UserPost, completion: @escaping (VoidResult) -> Void) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else {
            return
        }
        let databaseKey = "Posts/\(currentUserID)/\(post.postID)"
        
        databaseRef.child("Followers/\(currentUserID)").getData { [weak self] error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntUploadPost))
                return
            } else if let followersSnapshot = snapshot {

                var fanoutObj = [String: Any]()
                let postDictionary = post.createDictionary()

                if let followersData = followersSnapshot.value as? [String: AnyObject] {
                    let followers = followersData.keys
                    followers.forEach { follower in
                        fanoutObj["/Timelines/\(follower)/\(post.postID)"] = postDictionary
                    }
                }
                fanoutObj["Posts/\(currentUserID)/\(post.postID)"] = postDictionary
                fanoutObj["Timelines/\(currentUserID)/\(post.postID)"] = postDictionary
                fanoutObj["DiscoverPosts/\(post.postID)"] = postDictionary
                fanoutObj["Users/\(currentUserID)/hasPosts"] = true

                self?.databaseRef.updateChildValues(fanoutObj) { error, _ in
                    if let error = error {
                        completion(.failure(ServiceError.couldntUploadPost))
                    } else {
                        completion(.success)
                    }
                }
            }
        }
    }

    // MARK: Delete Post

    func deletePost(postID: String, postImageURL: String, completion: @escaping (VoidResult) -> Void) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else {
            return
        }
        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        databaseRef.child("Posts/\(currentUserID)/\(postID)").removeValue { error, _ in
            if let error = error {
                completion(.failure(ServiceError.couldntDeletePost))
                return
            } else {
                dispatchGroup.leave()
            }
        }

        dispatchGroup.enter()
        databaseRef.child("DiscoverPosts/\(postID)").removeValue { error, _ in
            if let error = error {
                completion(.failure(ServiceError.couldntDeletePost))
                return
            } else {
                dispatchGroup.leave()
            }
        }

        dispatchGroup.enter()
        databaseRef.child("PostComments/\(postID)").removeValue { error, _ in
            if let error = error {
                completion(.failure(ServiceError.couldntDeletePost))
                return
            } else {
                dispatchGroup.leave()
            }
        }

        dispatchGroup.enter()
        databaseRef.child("PostsLikes/\(postID)").removeValue { error, _ in
            if let error = error {
                completion(.failure(ServiceError.couldntDeletePost))
                return
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        StorageManager.shared.deletePostPhoto(photoURL: postImageURL) { result in
            if case .failure(let error) = result {
                completion(.failure(ServiceError.couldntDeletePost))
                return
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        deletePostFromFollowersTimeline(postID: postID) { result in
            if case .failure(let error) = result {
                completion(.failure(error))
                return
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        deletePostFromBookmarks(postID: postID) { result in
            if case .failure(let error) = result {
                completion(.failure(error))
                return
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        ActivitySystemService.shared.removePostRelatedActivityEvents(postID: postID) { result in
            if case .failure(let error) = result {
                completion(.failure(ServiceError.couldntDeletePost))
                return
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        getPostCount(for: currentUserID) { result in
            switch result {
            case .success(let postsCount):
                if postsCount == 0 {
                    UserDataService.shared.changeHasPostsStatus(hasPostsStatus: false) { result in
                        if case .failure(let error) = result {
                            completion(.failure(ServiceError.couldntDeletePost))
                            return
                        }
                        dispatchGroup.leave()
                    }
                } else {
                    dispatchGroup.leave()
                }
            case .failure(let error):
                completion(.failure(ServiceError.couldntDeletePost))
                return
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(.success)
        }
    }

    func deletePostFromFollowersTimeline(postID: String, completion: @escaping (VoidResult) -> Void) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }
        let followersRef = databaseRef.child("Followers/\(currentUserID)")

        followersRef.getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntDeletePost))
                return
            } else if let followersSnapshot = snapshot {

                var postsToDelete = [String: Any]()

                if let followersDictionary = followersSnapshot.value as? [String: AnyObject] {
                    let followers = followersDictionary.keys
                    followers.forEach { follower in
                        postsToDelete["/Timelines/\(follower)/\(postID)"] = NSNull()
                    }
                }

                postsToDelete["/Timelines/\(currentUserID)/\(postID)"] = NSNull()

                self.databaseRef.updateChildValues(postsToDelete) { error, _ in
                    if let error = error {
                        completion(.failure(ServiceError.couldntDeletePost))
                    } else {
                        completion(.success)
                    }
                }
            }
        }
    }

    func deletePostFromBookmarks(postID: String, completion: @escaping (VoidResult) -> Void) {
        let reverseIndexBookmarksPath = "BookmarksReverseIndex/\(postID)"

        databaseRef.child(reverseIndexBookmarksPath).getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntDeletePost))
                return
            } else if let snapshot = snapshot {

                var bookmarksToRemove = [String: Any]()

                if let usersBookmarkedThePost = snapshot.value as? [String: [String: Any]] {
                    usersBookmarkedThePost.map { userID, bookmarkDict in
                        if let bookmarkID = bookmarkDict["bookmarkID"] {
                            bookmarksToRemove["Bookmarks/\(userID)/\(bookmarkID)"] = NSNull()
                            bookmarksToRemove[reverseIndexBookmarksPath + "/\(userID)"] = NSNull()
                        }
                    }
                }

                self.databaseRef.updateChildValues(bookmarksToRemove) { error, _ in
                    if let error = error {
                        completion(.failure(ServiceError.couldntDeletePost))
                    } else {
                        completion(.success)
                    }
                }
            }
        }
    }

    func getPostCount(for userID: String, completion: @escaping (Result<PostCount, Error>) -> Void) {
        let databaseKey = "Posts/\(userID)/"

        databaseRef.child(databaseKey).getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadData))
                return
            } else if let snapshot = snapshot {
                completion(.success(Int(snapshot.childrenCount)))
            }
        }
    }

    //MARK: Get Post
    func getPost(ofUser user: String, postID: String, completion: @escaping (Result<UserPost, Error>) -> Void) {
        let databaseKey = "Posts/\(user)/\(postID)"

        databaseRef.child(databaseKey).getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadData))
                return
            } else if let snapshot = snapshot {

                guard let postDictionary = snapshot.value as? [String: Any] else {
                    completion(.failure(ServiceError.snapshotCastingError))
                    return
                }
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
                    let decodedPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                    UserDataService.shared.getUser(for: decodedPost.userID) { result in
                        switch result {
                        case .success(let user):
                            decodedPost.author = user
                        case .failure(let error):
                            completion(.failure(ServiceError.couldntLoadData))
                        }
                        completion(.success(decodedPost))
                    }
                } catch {
                    completion(.failure(ServiceError.jsonParsingError))
                }
            }
        }
    }

    func getPosts(quantity: UInt, for userID: String, completion: @escaping CompletionBlockWithPosts) {
        let databaseKey = "Posts/\(userID)/"

        databaseRef.child(databaseKey).queryOrderedByKey().queryLimited(toLast: quantity).getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadPosts))
                return
            } else if let snapshot = snapshot {

                var retrievedPosts = [UserPost]()
                var lastPostKey = ""
                var postsAuthor = ZoogramUser()
                let dispatchGroup = DispatchGroup()

                for snapshotChild in snapshot.children.reversed() {

                    guard let postSnapshot = snapshotChild as? DataSnapshot,
                          let postDictionary = postSnapshot.value as? [String: Any]
                    else {
                        completion(.failure(ServiceError.snapshotCastingError))
                        break
                    }
                    dispatchGroup.enter()
                    lastPostKey = postSnapshot.key

                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
                        let decodedPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                        retrievedPosts.append(decodedPost)
                        dispatchGroup.leave()
                    } catch {
                        completion(.failure(ServiceError.jsonParsingError))
                        break
                    }
                }

                dispatchGroup.enter()
                UserDataService.shared.getUser(for: userID) { result in
                    switch result {
                    case .success(let author):
                        postsAuthor = author
                    case .failure(let error):
                        completion(.failure(ServiceError.couldntLoadPosts))
                        break
                    }
                    dispatchGroup.leave()
                }

                dispatchGroup.notify(queue: .main) {
                    let postsWithAuthors = retrievedPosts.map { post in
                        post.author = postsAuthor
                        return post
                    }
                    print("retrieved posts: ", postsWithAuthors)
                    completion(.success((postsWithAuthors, lastPostKey)))
                }
            }
        }
    }

    func getMorePosts(quantity: UInt, after postKey: String, for userID: String, completion: @escaping CompletionBlockWithPosts) {
        let databaseKey = "Posts/\(userID)/"

        databaseRef.child(databaseKey).queryOrderedByKey().queryEnding(beforeValue: postKey).queryLimited(toLast: quantity).getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadPosts))
                return
            } else if let snapshot = snapshot {

                var lastRetrievedPostKey = ""
                var retrievedPosts = [UserPost]()
                var postsAuthor = ZoogramUser()
                let dispatchGroup = DispatchGroup()

                for snapshotChild in snapshot.children.reversed() {

                    guard let postSnapshot = snapshotChild as? DataSnapshot,
                          let postDictionary = postSnapshot.value as? [String: Any]
                    else {
                        completion(.failure(ServiceError.snapshotCastingError))
                        break
                    }
                    dispatchGroup.enter()
                    lastRetrievedPostKey = postSnapshot.key

                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
                        let decodedPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                        retrievedPosts.append(decodedPost)
                        dispatchGroup.leave()
                    } catch {
                        completion(.failure(ServiceError.jsonParsingError))
                        break
                    }
                }

                dispatchGroup.enter()
                UserDataService.shared.getUser(for: userID) { result in
                    switch result {
                    case .success(let author):
                        postsAuthor = author
                    case .failure(let error):
                        completion(.failure(ServiceError.couldntLoadPosts))
                        break
                    }
                    dispatchGroup.leave()
                }

                dispatchGroup.notify(queue: .main) {
                    let postsWithAuthor = retrievedPosts.map { post in
                        post.author = postsAuthor
                        return post
                    }
                    completion(.success((postsWithAuthor, lastRetrievedPostKey)))
                }
            }
        }
    }
}
