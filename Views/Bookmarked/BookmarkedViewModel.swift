//
//  BookmarkedViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 10.03.2023.
//

import Foundation

class BookmarksViewModel {

    private var service: any BookmarkedPostsServiceProtocol

    var bookmarks = [Bookmark]()

    init(service: any BookmarkedPostsServiceProtocol) {
        self.service = service
    }

    func isPaginationAllowed() -> Bool {
        return service.hasHitTheEndOfPosts == false && service.isAlreadyPaginating == false
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
        }
        return paginatedBookmarks
    }

    func hasHitTheEndOfBookmarks() -> Bool {
        return service.hasHitTheEndOfPosts
    }

    func hasFinishedPagination() {
        service.isAlreadyPaginating = false
    }

    func checkIfHasLoadedData() -> Bool {
        service.numberOfRetrievedItems > 0
    }
}
