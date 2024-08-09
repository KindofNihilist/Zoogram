//
//  PostViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 18.10.2022.
//

import UIKit
import SDWebImage

typealias LikesCountTitle = String

struct PostViewModel: Sendable {

    var shouldDisplayAsPlaceholder: Bool = false

    var postModel: UserPost

    var author: ZoogramUser {
        return postModel.author
    }

    var postID: String {
        return postModel.postID
    }

    var isMadeByCurrentUser: Bool {
        return postModel.isMadeByCurrentUser()
    }
    var isNewlyCreated: Bool {
        return postModel.isNewlyCreated
    }
    var postedDate: Date {
        return postModel.postedDate
    }

    var postImage: UIImage {
        return postModel.image ?? UIImage()
    }

    var postImageURL: String {
        return postModel.photoURL
    }

    var unAttributedPostCaption: String? {
        return postModel.caption
    }

    var likeState: LikeState {
        return postModel.likeState
    }

    var bookmarkState: BookmarkState {
        return postModel.bookmarkState
    }

    var likesCount: Int {
        return postModel.likesCount
    }

    var commentsCount: Int? {
        return postModel.commentsCount
    }

    var postCaption: AttributedString? {
        return createFormatedPostCaption(caption: self.unAttributedPostCaption, username: self.author.username)
    }

    var timeSincePostedTitle: String {
        return createTitleFor(timeSincePosted: self.postedDate)
    }

    var likesCountTitle: LikesCountTitle {
        return createTitleFor(likesCount: self.likesCount)
    }

    var commentsCountTitle: String? {
        return createTitleFor(commentsCount: self.commentsCount)
    }

    init(post: UserPost) {
        self.postModel = post
    }

    mutating func switchLikeState() {
        postModel.switchLikeState()
    }

    mutating func switchBookmarkState() {
        postModel.switchBookmarkState()
    }

    mutating func changeIsNewlyCreatedStatus(to value: Bool) {
        postModel.changeIsNewlyCreatedStatus(to: value)
    }

    static func createPlaceholderViewModel() -> PostViewModel {
        var postViewModel = PostViewModel(post: UserPost.createNewPostModel())
        postViewModel.shouldDisplayAsPlaceholder = true
        return postViewModel
    }

    private func createFormatedPostCaption(caption: String?, username: String) -> AttributedString? {
        guard let caption = caption else {
            return nil
        }

        var usernameWithCaption = AttributedString()

        var attributedUsername = AttributedString("\(username) ")
        attributedUsername.font = CustomFonts.boldFont(ofSize: 14)
        attributedUsername.foregroundColor = Colors.label
        usernameWithCaption.append(attributedUsername)

        var attributedCaption = AttributedString(caption)
        attributedCaption.font = CustomFonts.regularFont(ofSize: 14)
        attributedCaption.foregroundColor = Colors.label
        usernameWithCaption.append(attributedCaption)
        return usernameWithCaption
    }

    private func createTitleFor(likesCount: Int) -> String {
        return String(localized: "\(likesCount) like")
    }

    private func createTitleFor(commentsCount: Int?) -> String? {
        guard let count = commentsCount, count > 0 else {
            return nil
        }
        return String(localized: "View \(count) comment")
    }

    private func createTitleFor(timeSincePosted: Date) -> String {
        return timeSincePosted.timeAgoDisplay()
    }
}
