//
//  NewPostService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.12.2022.
//

import Foundation
@preconcurrency import FirebaseDatabase

typealias PostCount = Int
typealias PhotoURLString = String

protocol UserPostsServiceProtocol: Sendable {
    func insertNewPost(post: UserPost) async throws
    func deletePost(postID: String, postImageURL: String) async throws
    func createDeletePostFromFollowersTimelineActions(postID: String) async throws -> [String: Any]
    func createDeletePostRelatedActivityEventsActions(postID: String) async throws -> [String: Any]
    func createDeletePostFromBookmarksActions(postID: String) async throws -> [String: Any]
    func getPost(ofUser user: String, postID: String) async throws -> UserPost
    func getPostCount(for userID: UserID) async throws -> PostCount
    func getPosts(quantity: UInt, for userID: UserID) async throws -> PaginatedItems<UserPost>
    func getMorePosts(quantity: UInt, after postKey: String, for userID: UserID) async throws -> PaginatedItems<UserPost>
}

final class UserPostsService: UserPostsServiceProtocol {

    static let shared = UserPostsService()

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    func createPostUID() -> String {
        return databaseRef.child("Posts").childByAutoId().key!
    }

    // MARK: Create post
    // By using multipath batch updates this method creates new post entry for user, fans it out to every follower timeline and adds it to Discover tab timeline all in one write. So it either succeeds or fails, no midpoint results.
    // Previously this method relied on other methods with seperate write transactions, but if the connection were to interrup
    // that would result in inconsistency.

    func insertNewPost(post: UserPost) async throws {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let databaseKey = "Followers/\(currentUserID)"
        let query = databaseRef.child(databaseKey)

        do {
            let data = try await query.getData()

            var fanoutObj = [String: Any]()
            let postDictionary = post.createDictionary()

            if let followersData = data.value as? [String: AnyObject] {
                let followers = followersData.keys
                followers.forEach { follower in
                    fanoutObj["/Timelines/\(follower)/\(post.postID)"] = postDictionary
                }
            }
            fanoutObj["Posts/\(currentUserID)/\(post.postID)"] = postDictionary
            fanoutObj["Timelines/\(currentUserID)/\(post.postID)"] = postDictionary
            fanoutObj["DiscoverPosts/\(post.postID)"] = postDictionary
            try await databaseRef.updateChildValues(fanoutObj)
        } catch {
            throw ServiceError.couldntUploadPost
        }
    }

    // MARK: Delete Post
    func deletePost(postID: String, postImageURL: String) async throws {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()

        var deleteActions = [String: Any]()
        deleteActions["Posts/\(currentUserID)/\(postID)"] = NSNull()
        deleteActions["DiscoverPosts/\(postID)"] = NSNull()
        deleteActions["PostComments/\(postID)"] = NSNull()
        deleteActions["PostsLikes/\(postID)"] = NSNull()

        do {
            let deleteFromFollowersTimelinesAction = try await createDeletePostFromFollowersTimelineActions(postID: postID)
            let deleteFromBookmarksAction = try await createDeletePostFromBookmarksActions(postID: postID)
            let deleteFromActivityEventsAction = try await createDeletePostRelatedActivityEventsActions(postID: postID)

            deleteActions.merge(deleteFromFollowersTimelinesAction) { current, _ in current }
            deleteActions.merge(deleteFromActivityEventsAction) { current, _ in current }
            deleteActions.merge(deleteFromBookmarksAction) { current, _ in current }

            try await databaseRef.updateChildValues(deleteActions)
            try await StorageManager.shared.deletePostPhoto(photoURL: postImageURL)
        } catch {
            print(error.localizedDescription)
            throw ServiceError.couldntDeletePost
        }
    }

    func createDeletePostFromFollowersTimelineActions(postID: String) async throws -> [String: Any] {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let query = databaseRef.child("Followers/\(currentUserID)")
        let data = try await query.getData()

        var postsToDelete = [String: Any]()
        postsToDelete["/Timelines/\(currentUserID)/\(postID)"] = NSNull()
        if let followersDictionary = data.value as? [String: Any] {
            let followers = followersDictionary.keys
            followers.forEach { follower in
                postsToDelete["/Timelines/\(follower)/\(postID)"] = NSNull()
            }
        }
        return postsToDelete
    }

    func createDeletePostFromBookmarksActions(postID: String) async throws -> [String: Any] {
        let reverseIndexBookmarksPath = "BookmarksReverseIndex/\(postID)"
        let query = databaseRef.child(reverseIndexBookmarksPath)
        let data = try await query.getData()
        var bookmarksToRemove = [String: Any]()
        if let usersBookmarkedThePost = data.value as? [String: [String: Any]] {
        _ = usersBookmarkedThePost.map { userID, bookmarkDict in
                if let bookmarkID = bookmarkDict["bookmarkID"] {
                    bookmarksToRemove["Bookmarks/\(userID)/\(bookmarkID)"] = NSNull()
                    bookmarksToRemove[reverseIndexBookmarksPath + "/\(userID)"] = NSNull()
                }
            }
        }
        return bookmarksToRemove
    }

    func createDeletePostRelatedActivityEventsActions(postID: String) async throws -> [String: Any] {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let path = "Activity/\(currentUserID)"
        let query = databaseRef.child(path).queryOrdered(byChild: "postID").queryEqual(toValue: postID)
        let data = try await query.getData()

        var activityEventToDelete = [String: Any]()
        for snapshot in data.children {
            guard let snapshotDict = snapshot as? DataSnapshot else {
                throw ServiceError.snapshotCastingError
            }
            let eventID = snapshotDict.key
            activityEventToDelete["Activity/\(currentUserID)/\(eventID)"] = NSNull()
        }
        return activityEventToDelete
    }

    // MARK: Get Post
    func getPostCount(for userID: UserID) async throws -> PostCount {
        let databaseKey = "Posts/\(userID)/"
        let query = databaseRef.child(databaseKey)

        do {
            let data = try await query.getData()
            return Int(data.childrenCount)
        } catch {
            throw ServiceError.couldntLoadPosts
        }
    }

    func getPost(ofUser user: String, postID: String) async throws -> UserPost {
        let databaseKey = "Posts/\(user)/\(postID)"

        do {
            let data = try await databaseRef.child(databaseKey).getData()

            guard let postDictionary = data.value as? [String: Any] else { throw ServiceError.snapshotCastingError }
            let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
            var decodedPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
            decodedPost.author = try await UserDataService().getUser(for: decodedPost.userID)
            return decodedPost
        } catch {
            throw ServiceError.couldntLoadPost
        }
    }

    func getPosts(quantity: UInt, for userID: UserID) async throws -> PaginatedItems<UserPost> {
        let databaseKey = "Posts/\(userID)/"
        let query = databaseRef.child(databaseKey).queryOrderedByKey().queryLimited(toLast: quantity)

        do {
            let data = try await query.getData()

            var retrievedPosts = [UserPost]()
            var lastPostKey = ""
            let postsAuthor = try await UserDataService().getUser(for: userID)

            for snapshot in data.children.reversed() {
                guard let postSnapshot = snapshot as? DataSnapshot,
                      let postDictionary = postSnapshot.value as? [String: Any]
                else {
                    throw ServiceError.snapshotCastingError
                }
                lastPostKey = postSnapshot.key

                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
                    var decodedPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                    decodedPost.author = postsAuthor
                    retrievedPosts.append(decodedPost)
                } catch {
                    throw error
                }
            }
            return PaginatedItems(items: retrievedPosts, lastRetrievedItemKey: lastPostKey)
        } catch {
            throw ServiceError.couldntLoadPosts
        }
    }

    func getMorePosts(quantity: UInt, after postKey: String, for userID: UserID) async throws -> PaginatedItems<UserPost> {
        let databaseKey = "Posts/\(userID)/"
        let query = databaseRef.child(databaseKey).queryOrderedByKey().queryEnding(beforeValue: postKey).queryLimited(toLast: quantity)

        do {
            let data = try await query.getData()

            var lastRetrievedPostKey = ""
            var retrievedPosts = [UserPost]()
            let postsAuthor = try await UserDataService().getUser(for: userID)

            for snapshot in data.children.reversed() {
                guard let postSnapshot = snapshot as? DataSnapshot,
                      let postDictionary = postSnapshot.value as? [String: Any]
                else {
                    throw ServiceError.snapshotCastingError
                }
                lastRetrievedPostKey = postSnapshot.key
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: postDictionary as Any)
                    var decodedPost = try JSONDecoder().decode(UserPost.self, from: jsonData)
                    decodedPost.author = postsAuthor
                    retrievedPosts.append(decodedPost)
                } catch {
                    throw ServiceError.jsonParsingError
                }
            }
            return PaginatedItems(items: retrievedPosts, lastRetrievedItemKey: lastRetrievedPostKey)
        } catch {
            throw ServiceError.couldntLoadPosts
        }
    }
}
