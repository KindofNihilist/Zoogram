//
//  FakePosts.swift
//  ZoogramTests
//
//  Created by Artem Dolbiiev on 10.07.2024.
//

@testable import Zoogram

import Foundation
final class Helpers {

    static func getFakePosts(count: UInt) -> [UserPost] {
        var posts = [UserPost]()
        for index in 0..<count {
            let fakePost = UserPost(
                userID: "fakeUserID_\(index)",
                postID: "fakePostID_\(index)",
                photoURL: "fakePhotoURL_\(index)",
                caption: "fakeCaption_\(index)",
                likeCount: Int(index),
                commentsCount: Int(index),
                postedDate: Date())
            posts.append(fakePost)
        }
        return posts
    }
}
