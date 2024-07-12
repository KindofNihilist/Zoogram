//
//  PostsService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 08.04.2023.
//

import Foundation
import SDWebImage

protocol PostsNetworking<ItemType>: Sendable, PostActionsService, Paginatable, AdditionalPostDataSource where ItemType: PostViewModelProvider {}

protocol PostActionsService {
    func likePost(postID: String, likeState: LikeState, postAuthorID: String) async throws
    func deletePost(postModel: PostViewModel) async throws
    func bookmarkPost(postID: String, authorID: String, bookmarkState: BookmarkState) async throws
}

protocol AdditionalPostDataSource: Sendable {
    var userDataService: UserDataServiceProtocol { get }
    var likeSystemService: LikeSystemServiceProtocol { get }
    var bookmarksService: BookmarksSystemServiceProtocol { get }
    var imageService: ImageServiceProtocol { get }
    var commentsService: CommentSystemServiceProtocol { get }

    func getAdditionalPostDataFor(postsOfMultipleUsers: [UserPost]) async throws -> [UserPost]
    func getAdditionalPostDataFor(postsOfSingleUser: [UserPost]) async throws -> [UserPost]
}

struct PaginatedItems<ItemType: PostViewModelProvider> {
    var items: [ItemType]
    var lastRetrievedItemKey: String
}

actor PaginationManager {

    let numberOfItemsToGetPerPagination: UInt
    private var numberOfAllItems: Int = 0
    private var numberOfRetrievedItems: Int = 0
    private var isPaginationInProgress: Bool = false
    private var lastReceivedItemKey: String = ""

    private var paginationAllowed: Bool {
        return isPaginationInProgress == false && hasHitTheEndOfItems == false
    }

    private var hasHitTheEndOfItems: Bool {
        return numberOfAllItems == numberOfRetrievedItems
    }

    init(numberOfItemsToGetPerPagination: UInt) {
        self.numberOfItemsToGetPerPagination = numberOfItemsToGetPerPagination
    }

    func setNumberOfAllItems(_ itemsCount: Int) {
        self.numberOfAllItems = itemsCount
    }

    func resetNumberOfRetrievedItems() {
        self.numberOfRetrievedItems = 0
    }
    
    func updateNumberOfRetrievedItems(value: Int) {
        self.numberOfRetrievedItems += value
    }

    func getNumberOfAllItems() -> Int {
        return self.numberOfAllItems
    }

    func getNumberOfRetrievedItems() -> Int {
        return self.numberOfRetrievedItems
    }

    func startPaginating() {
        self.isPaginationInProgress = true
    }

    func finishPaginating() {
        print("has finished pagination")
        self.isPaginationInProgress = false
    }

    func isPaginating() -> Bool {
        return self.isPaginationInProgress
    }

    func getLastReceivedItemKey() -> String {
        return lastReceivedItemKey
    }

    func setLastReceivedItemKey(_ key: String) {
        self.lastReceivedItemKey = key
    }

    func isPaginationAllowed() -> Bool {
        return paginationAllowed
    }

    func checkIfHasHitEndOfItems() -> Bool {
        return hasHitTheEndOfItems
    }

    func shouldReloadData() async -> Bool {
        let numberOfRetrievedItems = self.numberOfRetrievedItems
        let numberOfAllItems = self.numberOfAllItems
        let numberOfItemsToGet = self.numberOfItemsToGetPerPagination
        let hasntRetrievedItems = numberOfRetrievedItems == 0
        
        let numberOfReceivedItemsIsLessThanRequired = numberOfRetrievedItems < numberOfItemsToGet
        let hasntRetrievedAllItems = numberOfRetrievedItems < numberOfAllItems
        let retrievedLessItemsThanRequired = numberOfReceivedItemsIsLessThanRequired && hasntRetrievedAllItems

        if hasntRetrievedItems || retrievedLessItemsThanRequired {
            return true
        } else {
            return false
        }
    }
}

protocol Paginatable {
    associatedtype ItemType = PostViewModelProvider
    var paginationManager: PaginationManager {get}
    func getNumberOfItems() async throws -> Int
    func getItems() async throws -> [ItemType]?
    func getMoreItems() async throws -> [ItemType]?
    func isPaginating() async -> Bool
    func checkIfHasHitEndOfItems() async -> Bool
}

extension Paginatable {
    func isPaginating() async -> Bool {
        return await paginationManager.isPaginating()
    }

    func checkIfHasHitEndOfItems() async -> Bool {
        return await paginationManager.checkIfHasHitEndOfItems()
    }
}

protocol PostViewModelProvider: Sendable {
    func getPostViewModel() -> PostViewModel?
}

extension AdditionalPostDataSource {

    func getAdditionalPostDataFor(postsOfMultipleUsers: [UserPost]) async throws -> [UserPost] {
        guard postsOfMultipleUsers.isEmpty != true else {
            return []
        }
        let postsWithAdditionalData = try await withThrowingTaskGroup(of: (Int, UserPost).self, returning: [UserPost].self) { group in
            for (index, post) in postsOfMultipleUsers.enumerated() {
                group.addTask {
                    var author = try await userDataService.getUser(for: post.userID)
                    var postWithAdditionalData = post
                    let postID = postWithAdditionalData.postID
                    let photoURL = postWithAdditionalData.photoURL
                    let profilePhotoURL = author.profilePhotoURL
                    async let profilePhoto = imageService.getImage(for: profilePhotoURL)
                    async let postPhoto = imageService.getImage(for: photoURL)
                    async let likesCount = likeSystemService.getLikesCountForPost(id: postID)
                    async let commentsCount = commentsService.getCommentsCountForPost(postID: postID)
                    async let bookmarkState = bookmarksService.checkIfBookmarked(postID: postID)
                    async let likeState = likeSystemService.checkIfPostIsLiked(postID: postID)

                    author.setProfilePhoto(try await profilePhoto)
                    postWithAdditionalData.author = author
                    postWithAdditionalData.image = try await postPhoto
                    postWithAdditionalData.likesCount = try await likesCount
                    postWithAdditionalData.commentsCount = try await commentsCount
                    postWithAdditionalData.bookmarkState = try await bookmarkState
                    postWithAdditionalData.likeState = try await likeState
                    return (index, postWithAdditionalData)
                }
            }

            var postsToReturn = postsOfMultipleUsers
            for try await (index, post) in group {
                postsToReturn[index] = post
            }
            return postsToReturn
        }
        return postsWithAdditionalData
    }

    func getAdditionalPostDataFor(postsOfSingleUser: [UserPost]) async throws -> [UserPost] {
        guard let authorID = postsOfSingleUser.first?.userID else { return [] }

        var author = try await userDataService.getUser(for: authorID)
        if let profilePhotoURL = author.profilePhotoURL {
            let profilePhoto = try await imageService.getImage(for: profilePhotoURL)
            author.setProfilePhoto(profilePhoto)
        }

        let postsWithAdditionalData = try await withThrowingTaskGroup(of: (Int, UserPost).self, returning: [UserPost].self) { group in

            for (index, post) in postsOfSingleUser.enumerated() {
                group.addTask { [author] in
                    var postWithAdditionalData = post
                    let postID = postWithAdditionalData.postID
                    let photoURL = postWithAdditionalData.photoURL
                    async let postPhoto = imageService.getImage(for: photoURL)
                    async let likesCount = likeSystemService.getLikesCountForPost(id: postID)
                    async let commentsCount = commentsService.getCommentsCountForPost(postID: postID)
                    async let bookmarkState = bookmarksService.checkIfBookmarked(postID: postID)
                    async let likeState = likeSystemService.checkIfPostIsLiked(postID: postID)

                    postWithAdditionalData.author = author
                    postWithAdditionalData.image = try await postPhoto
                    postWithAdditionalData.likesCount = try await likesCount
                    postWithAdditionalData.commentsCount = try await commentsCount
                    postWithAdditionalData.bookmarkState = try await bookmarkState
                    postWithAdditionalData.likeState = try await likeState
                    return (index, postWithAdditionalData)
                }
            }

            var postsToReturn = postsOfSingleUser
            for try await (index, post) in group {
                postsToReturn[index] = post
            }
            return postsToReturn
        }
        return postsWithAdditionalData
    }

    func getAdditionalPostDataFor(_ post: UserPost) async throws -> UserPost {
        var postWithData = post
        let author = try await userDataService.getUser(for: post.userID)
        if let profilePhotoURL = author.profilePhotoURL {
            let profilePhoto = try await imageService.getImage(for: profilePhotoURL)
            postWithData.author.setProfilePhoto(profilePhoto)
        }

        let postID = postWithData.postID
        let photoURL = postWithData.photoURL
        async let postPhoto = imageService.getImage(for: photoURL)
        async let likesCount = likeSystemService.getLikesCountForPost(id: postID)
        async let commentsCount = commentsService.getCommentsCountForPost(postID: postID)
        async let bookmarkState = bookmarksService.checkIfBookmarked(postID: postID)
        async let likeState = likeSystemService.checkIfPostIsLiked(postID: postID)

        postWithData.author = author
        postWithData.image = try await postPhoto
        postWithData.likesCount = try await likesCount
        postWithData.commentsCount = try await commentsCount
        postWithData.bookmarkState = try await bookmarkState
        postWithData.likeState = try await likeState
        return postWithData
    }
}
