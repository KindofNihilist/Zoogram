//
//  BookmarkedViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 10.03.2023.
//

import Foundation

@MainActor
class BookmarksViewModel {

    private var service: any BookmarkedPostsServiceProtocol

    var bookmarks = [Bookmark]()

    init(service: any BookmarkedPostsServiceProtocol) {
        self.service = service
    }

    func isPaginationAllowed() async -> Bool {
        let isPaginating = await service.paginationManager.isPaginating()
        let hasHitTheEndOfPosts = await service.checkIfHasHitEndOfItems()
        return hasHitTheEndOfPosts == false && isPaginating == false
    }

    func getBookmarks() async throws -> [Bookmark]? {
        let receivedBookmarks = try await service.getItems()
        if let receivedBookmarks = receivedBookmarks {
            self.bookmarks = receivedBookmarks
        }
        return bookmarks
    }

    func getMoreBookmarks() async throws -> [Bookmark]? {
        let paginatedBookmarks = try await service.getMoreItems()
        if let paginatedBookmarks = paginatedBookmarks {
            self.bookmarks.append(contentsOf: paginatedBookmarks)
            return paginatedBookmarks
        } else {
            return nil
        }
    }

    func hasHitTheEndOfBookmarks() async -> Bool {
        return await service.checkIfHasHitEndOfItems()
    }

    func checkIfHasLoadedData() async -> Bool {
        let numberOfRetrievedItems = await service.paginationManager.getNumberOfRetrievedItems()
        return numberOfRetrievedItems > 0
    }
}
