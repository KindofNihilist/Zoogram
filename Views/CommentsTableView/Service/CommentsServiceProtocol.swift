//
//  PostWithCommentsService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 17.05.2023.
//

import Foundation
import SDWebImage

protocol CommentsServiceProtocol: ImageService, PostActionsService {
    var userDataService: UserDataServiceProtocol { get }
    var postsService: UserPostsServiceProtocol { get }
    var commentsService: CommentSystemServiceProtocol { get }
    var likesService: LikeSystemServiceProtocol { get }
    var bookmarksService: BookmarksSystemServiceProtocol { get }

    var postID: String { get set }
    var postAuthorID: String { get set }
    func getComments(completion: @escaping (Result<[PostComment], Error>) -> Void)
    func postComment(comment: PostComment, completion: @escaping (Result<PostComment, Error>) -> Void)
    func deleteComment(commentID: String, completion: @escaping (VoidResult) -> Void)
}

extension CommentsServiceProtocol {

    func getAdditionalPostData(for post: UserPost, completion: @escaping (Result<UserPost, Error>) -> Void) {

        let dispatchGroup = DispatchGroup()

        if let profilePhotoURL = post.author.profilePhotoURL {
            dispatchGroup.enter()
            getImage(for: profilePhotoURL) { result in
                switch result {
                case .success(let profilePhoto):
                    post.author.setProfilePhoto(profilePhoto)
                case .failure(let error):
                    completion(.failure(error))
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.enter()
        LikeSystemService.shared.getLikesCountForPost(id: post.postID) { result in
            switch result {
            case .success(let likesCount):
                post.likesCount = likesCount
            case.failure(let error):
                completion(.failure(error))
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
            }
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            completion(.success(post))
        }
    }
}

class CommentsService: ImageService, CommentsServiceProtocol {

    var postID: String

    var postAuthorID: String

    let userDataService: UserDataServiceProtocol
    let postsService: UserPostsServiceProtocol
    let commentsService: CommentSystemServiceProtocol
    let likesService: LikeSystemServiceProtocol
    let bookmarksService: BookmarksSystemServiceProtocol

    init(postID: String, 
         postAuthorID: String,
         userDataService: UserDataServiceProtocol,
         postsService: UserPostsServiceProtocol,
         commentsService: CommentSystemServiceProtocol,
         likesService: LikeSystemServiceProtocol,
         bookmarksService: BookmarksSystemServiceProtocol)
    {
        self.postID = postID
        self.postAuthorID = postAuthorID
        self.userDataService = userDataService
        self.postsService = postsService
        self.commentsService = commentsService
        self.likesService = likesService
        self.bookmarksService = bookmarksService
    }

    func getCurrentUser(completion: @escaping (ZoogramUser) -> Void) {
        userDataService.getLatestUserModel { result in
            switch result {
            case .success(let currentUser):
                completion(currentUser)
            case .failure(_):
                completion(ZoogramUser())
            }
        }
    }

    func getComments(completion: @escaping (Result<[PostComment], Error>) -> Void) {
        print("getcomments service called")
        commentsService.getCommentsForPost(postID: postID) { result in
            print("getComments service completion called")
            print(result)
            switch result {
            case .success(let comments):
                let dispatchGroup = DispatchGroup()
                for comment in comments {
                    if let profilePhotoURL = comment.author.profilePhotoURL {
                        dispatchGroup.enter()
                        self.getImage(for: profilePhotoURL) { result in
                            switch result {
                            case .success(let image):
                                comment.author.setProfilePhoto(image)
                            case .failure(let error):
                                completion(.failure(error))
                                return
                            }
                            dispatchGroup.leave()
                        }
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    completion(.success(comments))
                }

            case .failure(let error):
                completion(.failure(error))
                return
            }

        }
    }

    func postComment(comment: PostComment, completion: @escaping (Result<PostComment, Error>) -> Void) {
        CommentSystemService.shared.postComment(for: postID, comment: comment) { result in
            switch result {
            case .success:
                let activityEvent = ActivityEvent.createActivityEventFor(comment: comment, postID: self.postID)

                ActivitySystemService.shared.addEventToUserActivity(event: activityEvent, userID: self.postAuthorID)

                // Receiveing newly made comment's author profile to append it to tableView
                self.userDataService.getUser(for: comment.authorID) { result in
                    switch result {
                    case .success(let author):
                        comment.author = author
                        completion(.success(comment))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func deleteComment(commentID: String, completion: @escaping (VoidResult) -> Void) {
        commentsService.deleteComment(postID: postID, commentID: commentID) { result in
            switch result {
            case .success:
                ActivitySystemService.shared.removeCommentEventForPost(commentID: commentID, postAuthorID: self.postAuthorID)
                completion(.success)

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func likePost(postID: String, likeState: LikeState, postAuthorID: String, completion: @escaping (Result<LikeState, Error>) -> Void) {

        switch likeState {
        case .liked:
            likesService.removeLikeFromPost(postID: postID) { result in
                switch result {
                case .success:
                    ActivitySystemService.shared.removeLikeEventForPost(postID: postID, postAuthorID: postAuthorID)
                    completion(.success(.notLiked))

                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .notLiked:
            likesService.likePost(postID: postID) { result in
                switch result {
                case .success:
                    let activityEvent = ActivityEvent.createActivityEventFor(likedPostID: postID)

                    ActivitySystemService.shared.addEventToUserActivity(event: activityEvent, userID: postAuthorID)
                    completion(.success(.liked))

                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    func deletePost(postModel: PostViewModel, completion: @escaping (VoidResult) -> Void) {
        postsService.deletePost(postID: postModel.postID, postImageURL: postModel.postImageURL) { result in
            completion(result)
        }
    }

    func bookmarkPost(postID: String, authorID: String, bookmarkState: BookmarkState, completion: @escaping (Result<BookmarkState, Error>) -> Void) {

        switch bookmarkState {
        case .bookmarked:
            bookmarksService.removeBookmark(postID: postID) { bookmarkState in
                completion(bookmarkState)
            }

        case .notBookmarked:
            bookmarksService.bookmarkPost(postID: postID, authorID: authorID) { bookmarkState in
                completion(bookmarkState)
            }
        }
    }
}
