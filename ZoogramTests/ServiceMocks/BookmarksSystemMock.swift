//
//  BookmarksSystemMock.swift
//  ZoogramTests
//
//  Created by Artem Dolbiiev on 10.07.2024.
//

import Foundation
@testable import Zoogram

final class BookmarksSystemMock: BookmarksSystemServiceProtocol {
    func bookmarkPost(postID: String, authorID: String) async throws {
        return
    }
    
    func removeBookmark(postID: String) async throws {
        return
    }
    
    func checkIfBookmarked(postID: String) async throws -> Zoogram.BookmarkState {
        return .bookmarked
    }
    
    func getBookmarksCount() async throws -> Zoogram.BookmarksCount {
        return 0
    }
    
    func getBookmarks(numberOfBookmarksToGet: UInt) async throws -> Zoogram.PaginatedItems<Zoogram.Bookmark> {
        return PaginatedItems(items: [], lastRetrievedItemKey: "")
    }
    
    func getMoreBookmarks(after bookmarkKey: String, numberOfBookmarksToGet: UInt) async throws -> Zoogram.PaginatedItems<Zoogram.Bookmark> {
        return PaginatedItems(items: [], lastRetrievedItemKey: "")
    }
}
