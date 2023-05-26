//
//  PostViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 18.10.2022.
//

import UIKit
import SDWebImage

class PostViewModel {
    let postID: String
    let author: ZoogramUser
    let isMadeByCurrentUser: Bool
    var isNewlyCreated: Bool
    var shouldShowBlankCell: Bool = false

    let postImage: UIImage
    let postImageURL: String
    let postCaption: NSMutableAttributedString?
    let unAttributedPostCaption: String?

    var likeState: LikeState
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

        self.likesCount = post.likesCount ?? 0
        self.commentsCount = post.commentsCount
    }

    init() {
        self.postID = ""
        self.author = ZoogramUser()
        self.isMadeByCurrentUser = true
        self.postImage = UIImage(systemName: "photo")!
        self.postImageURL = ""
        self.postCaption = NSMutableAttributedString()
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

    class func createBlankViewModel() -> PostViewModel {
        let postViewModel = PostViewModel()
        postViewModel.shouldShowBlankCell = true
        return postViewModel
    }

    class func formatPostCaption(caption: String?, username: String) -> NSMutableAttributedString? {
        guard let caption = caption else {
            return nil
        }

        let usernameWithCaption = NSMutableAttributedString()

        let attributedUsername = NSAttributedString(string: "\(username) ", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.label])
        usernameWithCaption.append(attributedUsername)
        
        let attributedCaption = NSAttributedString(string: caption, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.label])
        usernameWithCaption.append(attributedCaption)

        return usernameWithCaption
    }

    class func createTitleFor(likesCount: Int?) -> String {
        guard let likesCount = likesCount else {
            return "0 likes"
        }

        if likesCount == 1 {
            return "\(likesCount) like"
        } else {
            return "\(likesCount) likes"
        }
    }

    class func createTitleFor(commentsCount: Int?) -> String? {
        guard let count = commentsCount, count > 0 else {
            return nil
        }

        if commentsCount == 1 {
            return "View \(count) comment"
        } else {
            return "View all \(count) comments"
        }
    }

    class func createTitleFor(timeSincePosted: Date) -> String {
        return timeSincePosted.timeAgoDisplay()
    }
}

