//
//  UserProfileViewModelTests.swift
//  ZoogramTests
//
//  Created by Artem Dolbiiev on 09.07.2024.
//

import Testing
@testable import Zoogram

@MainActor
struct UserProfileViewModelTest {

    let posts = Helpers.getFakePosts(count: 36)

    lazy var service = UserProfileService(
        userID: fakeUserObject.userID,
        followService: FollowSystemMock(),
        userPostsService: UserPostsServiceMock(posts: self.posts),
        userService: UserDataServiceMock(),
        likeSystemService: LikeSystemMock(),
        bookmarksService: BookmarksSystemMock(),
        activityService: ActivitySystemMock(),
        imageService: ImageServiceMock(),
        commentsService: CommentsServiceMock())

    lazy var viewModel = UserProfileViewModel(service: service, user: fakeUserObject)

    @Test("Half-way pagination test") mutating func paginationTest() async throws {
        let numberOfItemsToGet = await service.paginationManager.numberOfItemsToGetPerPagination
        #expect(viewModel.posts.count == 0)
        try await viewModel.getPosts()
        #expect(viewModel.posts.count == (numberOfItemsToGet))
    }

    @Test("Pagination till the end of posts test") mutating func paginationFullTest() async throws {
        #expect(viewModel.posts.count == 0)
        try await viewModel.getPosts()
        let numberOfItemsToGet = await service.paginationManager.numberOfItemsToGetPerPagination
        let numberOfAllItems = await viewModel.service.paginationManager.getNumberOfAllItems()
        let numberOfPaginationIterations = (numberOfAllItems - viewModel.posts.count) / Int(numberOfItemsToGet)
        for _ in 0..<numberOfPaginationIterations {
            _ = try await viewModel.getMorePosts()
        }
        let numberOfRetrievedItems = await viewModel.service.paginationManager.getNumberOfRetrievedItems()
        #expect(numberOfAllItems == numberOfRetrievedItems)
        let hasHitTheEndOfPosts = await viewModel.hasHitTheEndOfPosts()
        #expect(hasHitTheEndOfPosts == true)
    }

    @Test mutating func isPaginationAllowedTest() async throws {
        let viewModel = self.viewModel
        let isPaginationAllowedInitially = await viewModel.isPaginationAllowed()
        #expect(isPaginationAllowedInitially == false)
        _ = try await viewModel.getPosts()
        let isPaginationAllowedAfterPagination = await viewModel.isPaginationAllowed()
        #expect(isPaginationAllowedAfterPagination == true)
        let numberOfItemsToGet = await service.paginationManager.numberOfItemsToGetPerPagination
        let numberOfAllItems = await viewModel.service.paginationManager.getNumberOfAllItems()
        let numberOfPaginationIterations = (numberOfAllItems - viewModel.posts.count) / Int(numberOfItemsToGet)
        for _ in 0..<numberOfPaginationIterations {
            _ = try await viewModel.getMorePosts()
        }
        let isPaginationAllowedAfterRetrievingAllPosts = await viewModel.isPaginationAllowed()
        #expect(isPaginationAllowedAfterRetrievingAllPosts == false)
    }
}
