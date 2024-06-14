//
//  PostViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 18.10.2022.
//

import UIKit
import SDWebImage

struct PostViewModel: Sendable {
    let postID: String
    let author: ZoogramUser
    let isMadeByCurrentUser: Bool
    var isNewlyCreated: Bool
    var datePosted: Date
    var shouldShowBlankCell: Bool = false

    let postImage: UIImage
    let postImageURL: String
    let postCaption: AttributedString?
    let unAttributedPostCaption: String?

    var likeState: LikeState {
        didSet {
            if likeState == .liked {
                self.likesCount += 1
            } else {
                self.likesCount -= 1
            }
        }
    }
    var bookmarkState: BookmarkState

    var likesCountTitle: String
    var commentsCountTitle: String?
    var timeSincePostedTitle: String

    var likesCount: Int {
        didSet {
            likesCountTitle = PostViewModel.createTitleFor(likesCount: likesCount)
        }
    }

    var commentsCount: Int? {
        didSet {
            commentsCountTitle = PostViewModel.createTitleFor(commentsCount: commentsCount)
        }
    }

    init(post: UserPost) {
        self.postID = post.postID
        self.author = post.author
        self.datePosted = post.postedDate
        self.isMadeByCurrentUser = post.isMadeByCurrentUser()
        self.postImage = post.image ?? UIImage()
        self.postImageURL = post.photoURL
        self.postCaption = PostViewModel.formatPostCaption(caption: post.caption, username: post.author.username)
        self.unAttributedPostCaption = post.caption
        self.bookmarkState = post.bookmarkState
        self.likeState = post.likeState
        self.isNewlyCreated = post.isNewlyCreated
        self.likesCountTitle = PostViewModel.createTitleFor(likesCount: post.likesCount)
        self.commentsCountTitle = PostViewModel.createTitleFor(commentsCount: post.commentsCount)
        self.timeSincePostedTitle = PostViewModel.createTitleFor(timeSincePosted: post.postedDate)
        self.likesCount = post.likesCount
        self.commentsCount = post.commentsCount
    }

    init(author: ZoogramUser) {
        self.postID = ""
        self.author = author
        self.datePosted = Date()
        self.isMadeByCurrentUser = true
        self.postImage = UIImage(systemName: "photo")!
        self.postImageURL = ""
        self.postCaption = AttributedString()
        self.unAttributedPostCaption = ""
        self.bookmarkState = .notBookmarked
        self.likeState = .notLiked
        self.isNewlyCreated = true
        self.likesCountTitle = ""
        self.commentsCountTitle = ""
        self.timeSincePostedTitle = ""
        self.likesCount = 0
        self.commentsCount = 0
    }

    static func createBlankViewModel() async -> PostViewModel {
        let author = await UserManager.shared.getCurrentUser()
        var postViewModel = PostViewModel(author: author)
        postViewModel.shouldShowBlankCell = true
        return postViewModel
    }

    static func formatPostCaption(caption: String?, username: String) -> AttributedString? {
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

    static func createTitleFor(likesCount: Int) -> String {
        return String(localized: "\(likesCount) like")
    }

    static func createTitleFor(commentsCount: Int?) -> String? {
        guard let count = commentsCount, count > 0 else {
            return nil
        }
        return String(localized: "View \(count) comment")
    }

    static func createTitleFor(timeSincePosted: Date) -> String {
        return timeSincePosted.timeAgoDisplay()
    }
}
