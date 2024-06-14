//
//  SearchService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.06.2024.
//

import Foundation
@preconcurrency import FirebaseDatabase

protocol SearchServiceProtocol: Sendable {
    func searchUserWith(username: String) async throws -> [ZoogramUser]
}

final class SearchService: SearchServiceProtocol {

    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()

    func searchUserWith(username: String) async throws -> [ZoogramUser] {
        let query = databaseRef.child(DatabaseKeys.users).queryOrdered(byChild: "username").queryStarting(atValue: username).queryEnding(atValue: "\(username)~")

        do {
            let data = try await query.getData()
            var foundUsers = [ZoogramUser]()

            for snapshot in data.children {
                guard let userSnapshot = snapshot as? DataSnapshot,
                      let userDictionary = userSnapshot.value as? [String: Any]
                else {
                    print("snapshotCasting error")
                    throw ServiceError.snapshotCastingError
                }
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: userDictionary as Any)
                    var decodedUser = try JSONDecoder().decode(ZoogramUser.self, from: jsonData)
                    decodedUser.followStatus = try await FollowSystemService.shared.checkFollowStatus(for: decodedUser.userID)
                    foundUsers.append(decodedUser)
                } catch {
                    print("decoding found user error")
                    throw error
                }
            }
            return foundUsers
        } catch {
            print("error: ", error)
            throw ServiceError.couldntCompleteTheSearch
        }
    }
}
