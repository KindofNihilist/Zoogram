//
//  PostViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 18.10.2022.
//

import UIKit
import SDWebImage

enum PostSubviewType {
    case header(profilePictureURL: String, username: String)
    case postContent(provider: UserPost)
    case actions(provider: String)
    case comment(comment: PostComment)
    case footer(provider: UserPost, username: String)
}

struct PostModel {
    let subviews: [PostSubviewType]
}

class PostViewModel {
    let postID: String
    let authorID: String
    let authorProfilePhoto: UIImage
    let authorUsername: String
    let isMadeByCurrentUser: Bool
    
    let postImage: UIImage
    let postImageURL: String
    let postCaption: NSMutableAttributedString
    let unAttributedPostCaption: String
    
    var likeState: LikeState
    var bookmarkState: BookmarkState
    
    var likesCountTitle: String
    var commentsCountTitle: String
    var timeSincePostedTitle: String
    
    var likesCount: Int {
        didSet {
            likesCountTitle = PostViewModel.createTitleFor(likesCount: likesCount)
        }
    }
    
    var commentsCount: Int {
        didSet {
            commentsCountTitle = PostViewModel.createTitleFor(commentsCount: commentsCount)
        }
    }
    
    init(post: UserPost) {
        postID = post.postID
        authorID = post.author.userID
        authorProfilePhoto = post.author.profilePhoto ?? UIImage()
        authorUsername = post.author.username
        isMadeByCurrentUser = post.isMadeByCurrentUser()
        postImage = post.image ?? UIImage()
        postImageURL = post.photoURL
        postCaption = PostViewModel.formatPostCaption(caption: post.caption, username: authorUsername)
        unAttributedPostCaption = post.caption
        bookmarkState = post.bookmarkState
        likeState = post.likeState
        
        likesCountTitle = PostViewModel.createTitleFor(likesCount: post.likesCount)
        commentsCountTitle = PostViewModel.createTitleFor(commentsCount: post.commentsCount)
        timeSincePostedTitle = PostViewModel.createTitleFor(timeSincePosted: post.postedDate)
        
        likesCount = post.likesCount
        commentsCount = post.commentsCount
        
    }
    
    class func formatPostCaption(caption: String, username: String) -> NSMutableAttributedString {
        let attributedUsername = NSAttributedString(string: "\(username) ", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.label])
        
        let attributedCaption = NSAttributedString(string: caption, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.label])
        
        let usernameWithCaption = NSMutableAttributedString()
        usernameWithCaption.append(attributedUsername)
        usernameWithCaption.append(attributedCaption)
        
        return usernameWithCaption
    }
    
    class func createTitleFor(likesCount: Int) -> String {
        if likesCount == 1 {
            return "\(likesCount) like"
        } else {
            return "\(likesCount) likes"
        }
    }
    
    class func createTitleFor(commentsCount: Int) -> String {
        guard commentsCount > 0 else {
            return ""
        }
        
        if commentsCount == 1 {
            return "View \(commentsCount) comment"
        } else {
            return "View all \(commentsCount) comments"
        }
    }
    
    class func createTitleFor(timeSincePosted: Date) -> String {
        return timeSincePosted.timeAgoDisplay()
    }
}

