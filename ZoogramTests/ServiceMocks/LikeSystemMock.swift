//
//  LikeSystemMock.swift
//  ZoogramTests
//
//  Created by Artem Dolbiiev on 10.07.2024.
//

import Foundation
@testable import Zoogram

final class LikeSystemMock: LikeSystemServiceProtocol {
    func checkIfPostIsLiked(postID: String) async throws -> Zoogram.LikeState {
        return .liked
    }
    
    func getLikesCountForPost(id: String) async throws -> LikesCount {
        return 0
    }
    
    func likePost(postID: String) async throws {
        return
    }
    
    func removeLikeFromPost(postID: String) async throws {
        return
    }
}
