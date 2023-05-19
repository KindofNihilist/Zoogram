//
//  Adapters.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 07.04.2023.
//

import Foundation

class UserPostsAPIServiceAdapter: PostsService {

    var lastReceivedPostKey: String = ""

    var isAlreadyPaginating: Bool = false
    var hasHitTheEndOfPosts: Bool = false

    func likePost(postID: String, likeState: LikeState, postAuthorID: String, completion: @escaping (LikeState) -> Void) {

    }

    func deletePost(postModel: PostViewModel, completion: @escaping () -> Void) {

    }

    func bookmarkPost(postID: String, authorID: String, bookmarkState: BookmarkState, completion: @escaping (BookmarkState) -> Void) {

    }

    func removeBookmark(postID: String) {

    }

    func getPosts(completion: @escaping ([PostViewModel]) -> Void) {

    }

    func getMorePosts(completion: @escaping ([PostViewModel]?) -> Void) {

    }
}
