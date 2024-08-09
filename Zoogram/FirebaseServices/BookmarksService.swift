//
//  BookmarksService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 10.03.2023.
//

import Foundation
@preconcurrency import FirebaseDatabase

typealias BookmarksCount = Int

protocol BookmarksSystemServiceProtocol: Sendable {
    typealias LastRetrievedBookmarkKey = String
    typealias LastItemIndex = Int
    typealias ListOfBookmarks = [Bookmark]
    typealias CompletionBlockWithBookmarks = (Result<([Bookmark], LastRetrievedBookmarkKey), Error>) -> Void

    func bookmarkPost(postID: String, authorID: String) async throws
    func removeBookmark(postID: String) async throws
    func checkIfBookmarked(postID: String) async throws -> BookmarkState
    func getBookmarksCount() async throws -> BookmarksCount
    func getBookmarks(numberOfBookmarksToGet: UInt) async throws -> PaginatedItems<Bookmark>
    func getMoreBookmarks(after bookmarkKey: String, numberOfBookmarksToGet: UInt) async throws -> PaginatedItems<Bookmark>
}

final class BookmarksSystemService: BookmarksSystemServiceProtocol {

    static let shared = BookmarksSystemService()

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    func bookmarkPost(postID: String, authorID: String) async throws {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let bookmarkDictionary = Bookmark(postID: postID, postAuthorID: authorID).createDictionary()
        let bookmarkUID = databaseRef.child("Bookmarks").childByAutoId().key
        let bookmarksPath = "Bookmarks/\(currentUserID)/\(bookmarkUID!)"
        let reverseIndexBookmarksPath = "BookmarksReverseIndex/\(postID)/\(currentUserID)"

        var updates = [String: Any]()
        updates[bookmarksPath] = bookmarkDictionary
        updates[reverseIndexBookmarksPath] = ["userID": currentUserID, "bookmarkID": bookmarkUID]

        do {
            try await databaseRef.updateChildValues(updates)
        } catch {
            throw ServiceError.couldntCompleteTheAction
        }
    }

    func removeBookmark(postID: String) async throws {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let bookmarksPath = "Bookmarks/\(currentUserID)"
        let reverseIndexBookmarksPath = "BookmarksReverseIndex/\(postID)/\(currentUserID)"
        var updates = [String: Any]()
        let query = databaseRef.child(bookmarksPath).queryOrdered(byChild: "postID").queryEqual(toValue: postID)

        do {
            let data = try await query.getData()

            guard let snapshotDict = data.value as? [String: Any],
                  let bookmarkUID = snapshotDict.keys.first
            else {
                throw ServiceError.snapshotCastingError
            }
            updates["Bookmarks/\(currentUserID)/\(bookmarkUID)"] = NSNull()
            updates[reverseIndexBookmarksPath] = NSNull()

            try await databaseRef.updateChildValues(updates)
        } catch {
            throw ServiceError.couldntCompleteTheAction
        }
    }

    func checkIfBookmarked(postID: String) async throws -> BookmarkState {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()

        let path = "Bookmarks/\(currentUserID)"
        let query = databaseRef.child(path).queryOrdered(byChild: "postID").queryEqual(toValue: postID)

        do {
            let data = try await query.getData()
            return data.exists() ? .bookmarked : .notBookmarked
        } catch {
            throw ServiceError.couldntLoadData
        }
    }

    func getBookmarksCount() async throws -> BookmarksCount {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        let databaseKey = "Bookmarks/\(currentUserID)/"
        do {
            let data = try await databaseRef.child(databaseKey).getData()
            return Int(data.childrenCount)
        } catch {
            throw ServiceError.couldntLoadBookmarks
        }
    }

    func getBookmarks(numberOfBookmarksToGet: UInt) async throws -> PaginatedItems<Bookmark> {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        var bookmarks = [Bookmark]()
        var lastRetrievedBookmarkKey: String = ""
        let path = "Bookmarks/\(currentUserID)"
        let query = databaseRef.child(path).queryOrderedByKey().queryLimited(toLast: numberOfBookmarksToGet)

        do {
            let data = try await query.getData()
            for snapshot in data.children.reversed() {
                guard let snapshot = snapshot as? DataSnapshot,
                      let snapshotDictionary = snapshot.value as? [String: Any]
                else {
                    throw ServiceError.snapshotCastingError
                }
                lastRetrievedBookmarkKey = snapshot.key
                let jsonData = try JSONSerialization.data(withJSONObject: snapshotDictionary as Any)
                let bookmark = try JSONDecoder().decode(Bookmark.self, from: jsonData)
                bookmarks.append(bookmark)
            }
            return PaginatedItems(items: bookmarks, lastRetrievedItemKey: lastRetrievedBookmarkKey)
        } catch {
            throw ServiceError.couldntLoadBookmarks
        }
    }

    func getMoreBookmarks(after bookmarkKey: String, numberOfBookmarksToGet: UInt) async throws -> PaginatedItems<Bookmark> {
        let currentUserID = try AuthenticationService.shared.getCurrentUserUID()
        var bookmarks = [Bookmark]()
        var lastRetrievedBookmarkKey: LastRetrievedBookmarkKey = ""
        let path = "Bookmarks/\(currentUserID)"
        let query = databaseRef.child(path).queryOrderedByKey().queryEnding(beforeValue: bookmarkKey).queryLimited(toLast: numberOfBookmarksToGet)

        do {
            let data = try await query.getData()

            for snapshot in data.children.reversed() {
                guard let snapshot = snapshot as? DataSnapshot,
                      let snapshotDictionary = snapshot.value as? [String: Any]
                else {
                    throw ServiceError.snapshotCastingError
                }
                lastRetrievedBookmarkKey = snapshot.key
                let jsonData = try JSONSerialization.data(withJSONObject: snapshotDictionary)
                let bookmark = try JSONDecoder().decode(Bookmark.self, from: jsonData)
                bookmarks.append(bookmark)
            }
            return PaginatedItems(items: bookmarks, lastRetrievedItemKey: lastRetrievedBookmarkKey)
        } catch {
            throw ServiceError.couldntLoadBookmarks
        }
    }
}
