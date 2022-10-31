//
//  PostViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 18.10.2022.
//

import UIKit

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
    
    var userPosts: [UserPost]
    
    var postsModels = [PostModel]()
    
    init(userPosts: [UserPost]) {
        self.userPosts = userPosts
        configurePostViewModels(from: userPosts)
    }
    
    func getUserInfo(for userUID: String, completion: @escaping (String, String) -> Void) {
        
        DatabaseManager.shared.getUser(for: userUID) { user in
            if let user = user {
                completion(user.username, user.profilePhotoURL)
            }
        }
    }
    
    func configurePostViewModels(from userPosts: [UserPost], completion: @escaping () -> Void = {}) {
        for post in userPosts {
            
            getUserInfo(for: post.userID) { username, profilePhotoURL in
                
                var postView = [PostSubviewType]()
                postView.append(PostSubviewType.header(profilePictureURL: profilePhotoURL, username: username))
                postView.append(PostSubviewType.postContent(provider: post))
                postView.append(PostSubviewType.actions(provider: ""))
                postView.append(PostSubviewType.footer(provider: post, username: username))
                
                self.postsModels.append(PostModel(subviews: postView))
            }
        }
        completion() 
    }
}
