//
//  PostsService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 08.04.2023.
//

import Foundation
import SDWebImage

protocol PostsNetworking<T>: PostActionsService, Paginatable, AdditionalPostDataSource where T: PostViewModelProvider {}

protocol PostActionsService {
    func likePost(postID: String, likeState: LikeState, postAuthorID: String, completion: @escaping (Result<LikeState, Error>) -> Void)
    func deletePost(postModel: PostViewModel, completion: @escaping (VoidResult) -> Void)
    func bookmarkPost(postID: String, authorID: String, bookmarkState: BookmarkState, completion: @escaping (Result<BookmarkState, Error>) -> Void)
}

protocol AdditionalPostDataSource: ImageService {
    func getAdditionalPostDataFor(postsOfMultipleUsers: [UserPost], completion: @escaping (Result<[UserPost], Error>) -> Void)
    func getAdditionalPostDataFor(postsOfSingleUser: [UserPost], completion: @escaping (Result<[UserPost], Error>) -> Void)
}

protocol Paginatable {
    associatedtype T = PostViewModelProvider
    var numberOfItemsToGet: UInt {get set}
    var numberOfAllItems: UInt {get set}
    var numberOfRetrievedItems: UInt {get set}
    var lastReceivedItemKey: String {get set}
    var isAlreadyPaginating: Bool {get set}
    var hasHitTheEndOfPosts: Bool {get set}
    func getNumberOfItems(completion: @escaping (Result<Int, Error>) -> Void)
    func getItems(completion: @escaping ([T]?, Error?) -> Void)
    func getMoreItems(completion: @escaping ([T]?, Error?) -> Void)
}

protocol PostViewModelProvider {
    func getPostViewModel() -> PostViewModel?
}

extension AdditionalPostDataSource {

    func getAdditionalPostDataFor(postsOfMultipleUsers: [UserPost], completion: @escaping (Result<[UserPost], Error>) -> Void) {
        guard postsOfMultipleUsers.isEmpty != true else {
            completion(.success([UserPost]()))
            return
        }
        let dispatchGroup = DispatchGroup()

        for post in postsOfMultipleUsers {
            if let profilePhotoURL = post.author.profilePhotoURL {
                dispatchGroup.enter()
                getImage(for: profilePhotoURL) { result in
                    switch result {
                    case .success(let profilePhoto):
                        post.author.setProfilePhoto(profilePhoto)
                    case .failure(let error):
                        completion(.failure(error))
                        return
                    }
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.enter()
            getImage(for: post.photoURL) { result in
                switch result {
                case .success(let postPhoto):
                    post.image = postPhoto
                case .failure(let error):
                    completion(.failure(error))
                    return
                }
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            LikeSystemService.shared.getLikesCountForPost(id: post.postID) { result in
                switch result {
                case .success(let likesCount):
                    post.likesCount = likesCount
                case .failure(let error):
                    completion(.failure(error))
                    return
                }
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            CommentSystemService.shared.getCommentsCountForPost(postID: post.postID) { result in
                switch result {
                case .success(let commentsCount):
                    post.commentsCount = commentsCount
                case .failure(let error):
                    completion(.failure(error))
                    return
                }
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            BookmarksSystemService.shared.checkIfBookmarked(postID: post.postID) { result in
                switch result {
                case .success(let bookmarkState):
                    post.bookmarkState = bookmarkState
                case .failure(let error):
                    completion(.failure(error))
                    return
                }
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            LikeSystemService.shared.checkIfPostIsLiked(postID: post.postID) { result in
                switch result {
                case .success(let likeState):
                    post.likeState = likeState
                case .failure(let error):
                    completion(.failure(error))
                    return
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(.success(postsOfMultipleUsers))
        }
    }

    func getAdditionalPostDataFor(postsOfSingleUser: [UserPost], completion: @escaping (Result<[UserPost], Error>) -> Void) {
        guard let postsAuthor = postsOfSingleUser.first?.author, postsOfSingleUser.isEmpty != true else {
            print("inside getAdditionalPostData guard")
            completion(.success(postsOfSingleUser))
            return
        }

        let dispatchGroup = DispatchGroup()

        if let profilePhotoURL = postsAuthor.profilePhotoURL {
            dispatchGroup.enter()
            getImage(for: profilePhotoURL) { result in
                switch result {
                case .success(let profilePhoto):
                    postsAuthor.setProfilePhoto(profilePhoto)
                case .failure(let error):
                    completion(.failure(error))
                    return
                }
                dispatchGroup.leave()
            }
        }

        for post in postsOfSingleUser {
            dispatchGroup.enter()
            getImage(for: post.photoURL) { result in
                switch result {
                case .success(let postPhoto):
                    post.image = postPhoto
                case .failure(let error):
                    completion(.failure(error))
                    return
                }
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            LikeSystemService.shared.getLikesCountForPost(id: post.postID) { result in
                switch result {
                case .success(let likesCount):
                    post.likesCount = likesCount
                case .failure(let error):
                    completion(.failure(error))
                    return
                }
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            CommentSystemService.shared.getCommentsCountForPost(postID: post.postID) { result in
                switch result {
                case .success(let commentsCount):
                    post.commentsCount = commentsCount
                case .failure(let error):
                    completion(.failure(error))
                    return
                }
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            BookmarksSystemService.shared.checkIfBookmarked(postID: post.postID) { result in
                switch result {
                case .success(let bookmarkState):
                    post.bookmarkState = bookmarkState
                case .failure(let error):
                    completion(.failure(error))
                    return
                }
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            LikeSystemService.shared.checkIfPostIsLiked(postID: post.postID) { result in
                switch result {
                case .success(let likeState):
                    post.likeState = likeState
                case .failure(let error):
                    completion(.failure(error))
                    return
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            let postsWithAttachedAuthor = postsOfSingleUser.map({ post in
                post.author = postsAuthor
                return post
            })
            print("got additional data for posts")
            completion(.success(postsWithAttachedAuthor))
        }
    }
}
