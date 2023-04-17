//
//  BookmarksService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 10.03.2023.
//

import Foundation
import FirebaseDatabase

typealias LastRetrievedBookmarkKey = String
typealias LastItemIndex = Int
typealias ListOfBookmarks = [Bookmark]

struct Bookmark {
    var postID: String
    var postAuthorID: String
}

class BookmarksService {
    
    static let shared = BookmarksService()
    
    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()
    
    private let currentUserID = AuthenticationManager.shared.getCurrentUserUID()
    
    
    func bookmarkPost(postID: String, authorID: String, completion: @escaping () -> Void) {
        let bookmarkUID = databaseRef.child("Bookmarks").childByAutoId().key
        let path = "Bookmarks/\(currentUserID)/\(bookmarkUID!)"
        
        databaseRef.child(path).setValue(["postID" : postID, "authorID" : authorID]) { error, _ in
            completion()
        }
    }
    
    func removeBookmark(postID: String, completion: @escaping () -> Void) {
        let path = "Bookmarks/\(currentUserID)"
        
        let query = databaseRef.child(path).queryOrdered(byChild: "postID").queryEqual(toValue: postID)
        
        query.observeSingleEvent(of: .value) { snapshot in
            for snapshotChild in snapshot.children {
                guard let snapChild = snapshotChild as? DataSnapshot else {
                    return
                }
                snapChild.ref.removeValue()
                completion()
            }
        }
    }
    
    func checkIfBookmarked(postID: String, completion: @escaping (BookmarkState) -> Void) {
        let path = "Bookmarks/\(currentUserID)"
        
        let query = databaseRef.child(path).queryOrdered(byChild: "postID").queryEqual(toValue: postID)
        
        query.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                completion(.bookmarked)
            } else {
                completion(.notBookmarked)
            }
        }
    }
    
    func getListOfBookmarkedPosts(completion: @escaping (ListOfBookmarks) -> Void) {
        let path = "Bookmarks/\(currentUserID)"
        
        var listOfBookmarkedPosts = ListOfBookmarks()
        
        databaseRef.child(path).observeSingleEvent(of: .value) { snapshot in
            
            for snapshotChild in snapshot.children {
                guard let snapChild = snapshotChild as? DataSnapshot,
                      let snapChildDictionary = snapChild.value as? [String : Any],
                      let postID = snapChildDictionary["postID"] as? String,
                      let postAuthorID = snapChildDictionary["authorID"] as? String
                else {
                    return
                }
                listOfBookmarkedPosts.append(Bookmark(
                    postID: postID,
                    postAuthorID: postAuthorID))
            }
            completion(listOfBookmarkedPosts)
        }
    }
    
    func getBookmarkedPosts(numberOfPostsToGet: UInt, completion: @escaping ([UserPost], LastRetrievedBookmarkKey) -> Void) {
        
        let path = "Bookmarks/\(currentUserID)"
        var dispatchGroup = DispatchGroup()
        var retrievedPosts = [UserPost]()
        var lastRetrievedBookmarkKey: LastRetrievedBookmarkKey = ""
        
        databaseRef.child(path).queryOrderedByKey().queryLimited(toLast: numberOfPostsToGet).observeSingleEvent(of: .value) { snapshot in
            
            for snapshotChild in snapshot.children {
                guard let snapChild = snapshotChild as? DataSnapshot,
                      let snapChildDictionary = snapChild.value as? [String : Any],
                      let postID = snapChildDictionary["postID"] as? String,
                      let postAuthorID = snapChildDictionary["authorID"] as? String
                else {
                    return
                }
                dispatchGroup.enter()
                UserPostsService.shared.getPost(ofUser: postAuthorID, postID: postID) { userPost in
                    print("POST INSIDE GET POST USER SERVICE ", userPost)
                    retrievedPosts.append(userPost)
                    lastRetrievedBookmarkKey = snapChild.key
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(retrievedPosts, lastRetrievedBookmarkKey)
            }
        }
    }
    
    func getMoreBookmarkedPosts(after bookmarkKey: String, numberOfPostsToGet: UInt, completion: @escaping ([UserPost], LastRetrievedBookmarkKey) -> Void) {
        
        let path = "Bookmarks/\(currentUserID)"
        var dispatchGroup = DispatchGroup()
        var retrievedPosts = [UserPost]()
        var lastRetrievedBookmarkKey: LastRetrievedBookmarkKey = ""
        
        databaseRef.child(path).queryOrderedByKey().queryEnding(beforeValue: bookmarkKey).queryLimited(toLast: numberOfPostsToGet).observeSingleEvent(of: .value) { snapshot in
            
            for snapshotChild in snapshot.children {
                guard let snapChild = snapshotChild as? DataSnapshot,
                      let snapChildDictionary = snapChild.value as? [String : Any],
                      let postID = snapChildDictionary["postID"] as? String,
                      let postAuthorID = snapChildDictionary["authorID"] as? String
                else {
                    return
                }
                dispatchGroup.enter()
                UserPostsService.shared.getPost(ofUser: postAuthorID, postID: postID) { userPost in
                    print("POST INSIDE GET POST USER SERVICE ", userPost)
                    retrievedPosts.append(userPost)
                    lastRetrievedBookmarkKey = snapChild.key
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(retrievedPosts, lastRetrievedBookmarkKey)
            }
        }
    }
}


//extension BookmarksService {
//
//    func createSeriesOfBookmarksToGet(listOfBookmarks: ListOfBookmarks, amountOfBookmarks: UInt, lastPaginatedBookmarkIndex: Int, completion: @escaping ( LastItemIndex) -> Void) -> ListOfBookmarks{
//
//        var listOfBookmarksToPaginate = ListOfBookmarks()
//
//        let startIndex = lastPaginatedBookmarkIndex == 0 ? lastPaginatedBookmarkIndex : listOfBookmarks.index(after: lastPaginatedBookmarkIndex) - 1
//
//        var endIndex = listOfBookmarks.index(startIndex, offsetBy: Int(amountOfBookmarks))
//
//        if endIndex > listOfBookmarks.endIndex {
//            endIndex = listOfBookmarks.endIndex
//        }
//
//        listOfBookmarksToPaginate = Array(listOfBookmarks[startIndex..<endIndex])
//
//        completion(endIndex)
//        return listOfBookmarksToPaginate
//
//    }
//}
