//
//  UserProfileViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.09.2022.
//

import Foundation
import SDWebImage

class UserProfileViewModel {
    
    var hasInitialized: Bool = false
    var isPaginating: Bool = false
    var isUserProfile: Bool = true
    var lastObtainedPostKey = ""
    
    var username: String = ""
    var name: String = ""
    var bio: String = ""
    var profilePhoto = UIImage()
    var postsCount: Int = 0
    var followersCount: Int = 0
    var followingCount: Int = 0
    var userID: String!
    var userPosts = [UserPost]()
    
    func initializeViewModel(userID: String, completion: @escaping () -> Void) {
        getUserDataFor(userID: userID) {
            self.getUserPosts() {
                self.hasInitialized = true
                completion()
            }
        }
    }
    
    
    func getUserDataFor(userID: String, completion: @escaping () -> Void) {
        DatabaseManager.shared.getUser(for: userID) { [weak self] user in
            guard let user = user else {
                return
            }
            self?.userID = user.userID
            self?.username = user.username
            self?.name = user.name
            self?.bio = user.bio ?? ""
            self?.postsCount = user.posts
            self?.followersCount = user.followers
            self?.followingCount = user.following
            
            SDWebImageManager.shared.loadImage(with: URL(string: user.profilePhotoURL), progress: .none) { image, _, _, _, _, _ in
                if let image = image {
                    self?.profilePhoto = image
                    completion()
                }
            }
        }
    }
    
    func getUserPosts(completion: @escaping () -> Void) {
        guard let userID = userID else {
            return
        }
        DatabaseManager.shared.getPosts(for: userID) { posts, lastObtainedPostKey in
            self.userPosts.append(contentsOf: posts)
            self.lastObtainedPostKey = lastObtainedPostKey
            print("Downloaded initials posts with last post key: \(lastObtainedPostKey)")
            completion()
        }
    }
    
    func getMoreUserPosts(completion: @escaping ([UserPost]) -> Void) {
        guard let userID = userID else {
            return
        }
        isPaginating = true
        
        DatabaseManager.shared.getMorePosts(after: lastObtainedPostKey, for: userID) { posts, lastDownloadedPostKey in
            print("Got more posts with last post key: \(lastDownloadedPostKey)")
            guard lastDownloadedPostKey != self.lastObtainedPostKey else {
                print("Hit the end of user posts")
                return
            }
            self.lastObtainedPostKey = lastDownloadedPostKey
            self.userPosts.append(contentsOf: posts)
            self.isPaginating = false
            completion(posts)
        }
    }
}
