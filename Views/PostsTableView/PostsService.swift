//
//  PostsService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 08.04.2023.
//

import Foundation
import SDWebImage

protocol PostActionsService {
    func likePost(postID: String, likeState: LikeState, postAuthorID: String, completion: @escaping (LikeState) -> Void)
    func deletePost(postModel: PostViewModel, completion: @escaping () -> Void)
    func bookmarkPost(postID: String, authorID: String, bookmarkState: BookmarkState, completion: @escaping (BookmarkState) -> Void)
}

protocol PostsService: PostActionsService, ImageService {
    var numberOfPostsToGet: UInt {get set}
    var lastReceivedPostKey: String {get set}
    var isAlreadyPaginating: Bool {get set}
    var hasHitTheEndOfPosts: Bool {get set}
    var isPaginationAllowed: Bool {get set}

    func getPosts(completion: @escaping ([PostViewModel]) -> Void)
    func getMorePosts(completion: @escaping ([PostViewModel]?) -> Void)
}

extension PostsService {

    func getAdditionalPostDataFor(postsOfMultipleUsers: [UserPost], completion: @escaping ([UserPost]) -> Void) {
        guard postsOfMultipleUsers.isEmpty != true else {
            completion([UserPost]())
            return
        }
        let dispatchGroup = DispatchGroup()

        for post in postsOfMultipleUsers {

            dispatchGroup.enter()
            let profilePhotoURL = URL(string: post.author.profilePhotoURL)
            getImage(for: post.author.profilePhotoURL) { profilePhoto in
                post.author.profilePhoto = profilePhoto
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            getImage(for: post.photoURL) { postPhoto in
                if let postPhoto = postPhoto {
                    post.image = postPhoto
                }
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            LikeSystemService.shared.getLikesCountForPost(id: post.postID) { likesCount in
                post.likesCount = likesCount
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            CommentSystemService.shared.getCommentsCountForPost(postID: post.postID) { commentsCount in
                post.commentsCount = commentsCount
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            BookmarksService.shared.checkIfBookmarked(postID: post.postID) { bookmarkState in
                post.bookmarkState = bookmarkState
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            LikeSystemService.shared.checkIfPostIsLiked(postID: post.postID) { likeState in
                post.likeState = likeState
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(postsOfMultipleUsers)
        }
    }

    func getAdditionalPostDataFor(postsOfSingleUser: [UserPost], completion: @escaping ([UserPost]) -> Void) {
        guard let postsAuthor = postsOfSingleUser.first?.author, postsOfSingleUser.isEmpty != true else {
            completion([UserPost]())
            return
        }

        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        getImage(for: postsAuthor.profilePhotoURL) { profilePhoto in
            postsAuthor.profilePhoto = profilePhoto
            dispatchGroup.leave()

        }

        for post in postsOfSingleUser {

            dispatchGroup.enter()
            getImage(for: post.photoURL) { postPhoto in
                if let postPhoto = postPhoto {
                    post.image = postPhoto
                }
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            LikeSystemService.shared.getLikesCountForPost(id: post.postID) { likesCount in
                post.likesCount = likesCount
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            CommentSystemService.shared.getCommentsCountForPost(postID: post.postID) { commentsCount in
                post.commentsCount = commentsCount
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            BookmarksService.shared.checkIfBookmarked(postID: post.postID) { bookmarkState in
                post.bookmarkState = bookmarkState
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            LikeSystemService.shared.checkIfPostIsLiked(postID: post.postID) { likeState in
                post.likeState = likeState
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(postsOfSingleUser.map({ post in
                post.author = postsAuthor
                return post
            }))
        }
    }
}
