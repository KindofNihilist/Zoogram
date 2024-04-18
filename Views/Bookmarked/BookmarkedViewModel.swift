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

    func getBookmarks(completion: @escaping (Result<[Bookmark]?, Error>) -> Void) {
        self.service.getItems { bookmarks, error in
            if let error = error {
                completion(.failure(error))
                return
            } else if let bookmarks = bookmarks {
                self.bookmarks = bookmarks
                completion(.success(bookmarks))
            } else {
                completion(.success(nil))
            }
        }
    }

    func getMoreBookmarks(completion: @escaping (Result<[Bookmark]?, Error>) -> Void) {
        self.service.getMoreItems { bookmarks, error in
            if let error = error {
                completion(.failure(error))
                return
            } else if let bookmarks = bookmarks {
                self.bookmarks.append(contentsOf: bookmarks)
                completion(.success(bookmarks))
            } else {
                completion(.success(nil))
            }
        }
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
