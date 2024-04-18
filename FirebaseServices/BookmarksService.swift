//
//  BookmarksService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 10.03.2023.
//

import Foundation
import FirebaseDatabase

typealias BookmarksCount = Int

protocol BookmarksSystemServiceProtocol {
    typealias LastRetrievedBookmarkKey = String
    typealias LastItemIndex = Int
    typealias ListOfBookmarks = [Bookmark]
    typealias CompletionBlockWithBookmarks = (Result<([Bookmark], LastRetrievedBookmarkKey), Error>) -> Void

    func bookmarkPost(postID: String, authorID: String, completion: @escaping (Result<BookmarkState, Error>) -> Void)
    func removeBookmark(postID: String, completion: @escaping (Result<BookmarkState, Error>) -> Void)
    func checkIfBookmarked(postID: String, completion: @escaping (Result<BookmarkState, Error>) -> Void)
    func getBookmarksCount(completion: @escaping (Result<BookmarksCount, Error>) -> Void)
    func getBookmarks(numberOfBookmarksToGet: UInt, completion: @escaping CompletionBlockWithBookmarks)
    func getMoreBookmarks(after bookmarkKey: String, numberOfBookmarksToGet: UInt, completion: @escaping CompletionBlockWithBookmarks)
}

class BookmarksSystemService: BookmarksSystemServiceProtocol {

    static let shared = BookmarksSystemService()

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    func bookmarkPost(postID: String, authorID: String, completion: @escaping (Result<BookmarkState, Error>) -> Void) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }

        let bookmarkDictionary = Bookmark(postID: postID, postAuthorID: authorID).createDictionary()
        let bookmarkUID = databaseRef.child("Bookmarks").childByAutoId().key
        let bookmarksPath = "Bookmarks/\(currentUserID)/\(bookmarkUID!)"
        let reverseIndexBookmarksPath = "BookmarksReverseIndex/\(postID)/\(currentUserID)"
        var updates = [String: Any]()

        updates[bookmarksPath] = bookmarkDictionary
        updates[reverseIndexBookmarksPath] = ["userID": currentUserID, "bookmarkID": bookmarkUID]

        databaseRef.updateChildValues(updates) { error, _ in
            if let error = error {
                completion(.failure(ServiceError.couldntCompleteTheAction))
            } else {
                completion(.success(.bookmarked))
            }
        }
    }

    func removeBookmark(postID: String, completion: @escaping (Result<BookmarkState, Error>) -> Void) {
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }

        let bookmarksPath = "Bookmarks/\(currentUserID)"
        let reverseIndexBookmarksPath = "BookmarksReverseIndex/\(postID)/\(currentUserID)"
        var updates = [String: Any]()
        let query = databaseRef.child(bookmarksPath).queryOrdered(byChild: "postID").queryEqual(toValue: postID)

        query.getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntCompleteTheAction))
                return
            } else if let snapshot = snapshot {

                guard let snapshotValue = snapshot.value as? [String: Any],
                      let bookmarkUID = snapshotValue.keys.first
                else {
                    completion(.failure(ServiceError.snapshotCastingError))
                    return
                }
                updates["Bookmarks/\(currentUserID)/\(bookmarkUID)"] = NSNull()
                updates[reverseIndexBookmarksPath] = NSNull()

                self.databaseRef.updateChildValues(updates) { error, _ in
                    if let error = error {
                        completion(.failure(ServiceError.couldntCompleteTheAction))
                    } else {
                        completion(.success(.notBookmarked))
                    }
                }
            }
        }
    }

    func checkIfBookmarked(postID: String, completion: @escaping (Result<BookmarkState, Error>) -> Void) {
        
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }

        let path = "Bookmarks/\(currentUserID)"
        let query = databaseRef.child(path).queryOrdered(byChild: "postID").queryEqual(toValue: postID)

        query.getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadData))
                print(error)
                return
            } else if let snapshot = snapshot {

                if snapshot.exists() {
                    completion(.success(.bookmarked))
                } else {
                    completion(.success(.notBookmarked))
                }
            }
        }
    }

    func getBookmarksCount(completion: @escaping (Result<BookmarksCount, Error>) -> Void) {
        
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }

        let databaseKey = "Bookmarks/\(currentUserID)/"

        databaseRef.child(databaseKey).getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadData))
                return
            } else if let snapshot = snapshot {

                let bookmarksCount = Int(snapshot.childrenCount)
                completion(.success(bookmarksCount))
            }
        }
    }

    func getBookmarks(numberOfBookmarksToGet: UInt, completion: @escaping CompletionBlockWithBookmarks) {
        
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }

        var bookmarks = [Bookmark]()
        var lastRetrievedBookmarkKey: LastRetrievedBookmarkKey = ""
        let path = "Bookmarks/\(currentUserID)"
        let query = databaseRef.child(path).queryOrderedByKey().queryLimited(toLast: numberOfBookmarksToGet)

        query.getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadBookmarks))
                return
            } else if let snapshot = snapshot {

                for snapshotChild in snapshot.children.reversed() {
                    guard let snapChild = snapshotChild as? DataSnapshot,
                          let snapChildDictionary = snapChild.value as? [String: Any]
                    else {
                        completion(.failure(ServiceError.snapshotCastingError))
                        return
                    }
                    lastRetrievedBookmarkKey = snapChild.key
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: snapChildDictionary as Any)
                        let bookmark = try JSONDecoder().decode(Bookmark.self, from: jsonData)
                        bookmarks.append(bookmark)
                    } catch {
                        completion(.failure(ServiceError.jsonParsingError))
                    }
                }
                completion(.success((bookmarks, lastRetrievedBookmarkKey)))
            }
        }
    }

    func getMoreBookmarks(after bookmarkKey: String, numberOfBookmarksToGet: UInt, completion: @escaping CompletionBlockWithBookmarks) {
        
        guard let currentUserID = AuthenticationService.shared.getCurrentUserUID() else { return }

        var bookmarks = [Bookmark]()
        var lastRetrievedBookmarkKey: LastRetrievedBookmarkKey = ""
        let path = "Bookmarks/\(currentUserID)"
        let query = databaseRef.child(path).queryOrderedByKey().queryEnding(beforeValue: bookmarkKey).queryLimited(toLast: numberOfBookmarksToGet)

        query.getData { error, snapshot in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadBookmarks))
                return
            } else if let snapshot = snapshot {

                for snapshotChild in snapshot.children.reversed() {
                    guard let snapChild = snapshotChild as? DataSnapshot,
                          let snapChildDictionary = snapChild.value as? [String: Any]
                    else {
                        completion(.failure(ServiceError.snapshotCastingError))
                        return
                    }
                    lastRetrievedBookmarkKey = snapChild.key
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: snapChildDictionary)
                        let bookmark = try JSONDecoder().decode(Bookmark.self, from: jsonData)
                        bookmarks.append(bookmark)
                    } catch {
                        completion(.failure(ServiceError.jsonParsingError))
                    }
                }
                completion(.success((bookmarks, lastRetrievedBookmarkKey)))
            }
        }
    }
}
