//
//  SearchService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.06.2024.
//

import Foundation
@preconcurrency import FirebaseDatabase

protocol SearchServiceProtocol: Sendable {
    func searchUserWith(partialString: String) async throws -> [UserID]
}

final class SearchService: SearchServiceProtocol {

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    func searchUserWith(partialString: String) async throws -> [UserID] {
        let userRef = self.databaseRef.child("UsernamesForLookup")
        let startString = partialString
        let endString = partialString + "\u{F8FF}"
        let query = userRef.queryOrdered(byChild: "username")
            .queryStarting(atValue: startString)
            .queryEnding(atValue: endString)
        do {
            let data = try await query.getData()
            var foundUserIDs = [UserID]()
            for snapshot in data.children {
                guard let dataSnapshot = snapshot as? DataSnapshot,
                      let dictionary = dataSnapshot.value as? [String: String],
                      let userID = dictionary["userID"]
                else {
                    throw ServiceError.snapshotCastingError
                }
                foundUserIDs.append(userID)
            }
            return foundUserIDs
        } catch {
            throw ServiceError.couldntCompleteTheSearch
        }
    }
}
