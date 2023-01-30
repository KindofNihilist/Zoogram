//
//  UserProfileViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.09.2022.
//

import Foundation
import SDWebImage

class UserProfileViewModel {
    
    var isInitialized: Bool = false
    var isPaginating: Bool = false
    var isUserProfile: Bool
    var isFollowed: FollowStatus
    var lastObtainedPostKey = ""
    
    var user: Observable<ZoogramUser> = Observable(ZoogramUser(userID: "",
                                                               profilePhotoURL: "",
                                                               email: "",
                                                               phoneNumber: "",
                                                               username: "",
                                                               name: "",
                                                               bio: "",
                                                               birthday: "",
                                                               gender: "",
                                                               posts: 0,
                                                               joinDate: 0))
    
    var profilePhoto: Observable<UIImage> = Observable(UIImage())
    var postsCount: Observable<String> = Observable("")
    var followersCount: Observable<String> = Observable("")
    var followingCount: Observable<String> = Observable("")
    
    var userPosts: Observable<[UserPost]> = Observable([])
    
    init(for uid: String, followStatus: FollowStatus, isUserProfile: Bool) {
        self.isFollowed = followStatus
        self.isUserProfile = isUserProfile
        
        print("Initialize for UID: \(uid)")
        
        getUserDataFor(userID: uid) {
            print("Got user data")
        }
        
        getUserPosts(for: uid) {
            print("Got first 12 posts")
            self.isInitialized = true
        }

        getPostsCount(userID: uid) {
            print("Got post count")
        }
        
        getFollowersCount(userID: uid) {
            print("Got followers count")
        }
        
        getFollowingCount(userID: uid) {
            print("Got following count")
        }
    }
    
    func getFollowersCount(userID: String, completion: @escaping () -> Void) {
        FollowService.shared.getFollowersNumber(for: userID) { followersCount in
            self.followersCount.value = "\(followersCount)"
            completion()
        }
    }
    
    func getFollowingCount(userID: String, completion: @escaping () -> Void) {
        FollowService.shared.getFollowingNumber(for: userID) { followingCount in
            self.followingCount.value = "\(followingCount)"
            completion()
        }
    }
    
    func getPostsCount(userID: String, completion: @escaping () -> Void) {
        UserPostService.shared.getPostCount(for: userID) { count in
            self.postsCount.value = String(count)
            completion()
        }
    }
    
    
    func getUserDataFor(userID: String, completion: @escaping () -> Void) {
        UserService.shared.getUser(for: userID) { [weak self] user in
            self?.user.value = user
            
            SDWebImageManager.shared.loadImage(with: URL(string: user.profilePhotoURL), progress: .none) { image, _, _, _, _, _ in
                if let image = image {
                    self?.profilePhoto.value = image
                    completion()
                }
            }
        }
    }
    
    func getUserPosts(for uid: String, completion: @escaping () -> Void) {
        UserPostService.shared.getPosts(for: uid) { posts, lastObtainedPostKey in
            self.userPosts.value?.append(contentsOf: posts)
            self.lastObtainedPostKey = lastObtainedPostKey
            print("Downloaded initials posts with last post key: \(lastObtainedPostKey)")
            completion()
        }
    }
    
    func getMoreUserPosts(completion: @escaping ([UserPost]) -> Void) {
        guard let userID = user.value?.userID,
        lastObtainedPostKey != "" else {
            return
        }
        
        isPaginating = true
        
        UserPostService.shared.getMorePosts(after: lastObtainedPostKey, for: userID) { posts, lastDownloadedPostKey in
            print("Prev last post key:", self.lastObtainedPostKey)
            print("Last downloaded post key:", lastDownloadedPostKey)
            print("Got more posts with last post key: \(lastDownloadedPostKey)")
            guard lastDownloadedPostKey != self.lastObtainedPostKey else {
                print("Hit the end of user posts")
                return
            }
            self.lastObtainedPostKey = lastDownloadedPostKey
            self.userPosts.value?.append(contentsOf: posts)
            self.isPaginating = false
            completion(posts)
        }
    }
    
    func followUser(completion: @escaping (Bool) -> Void) {
        guard let userID = user.value?.userID else {
            return
        }
        FollowService.shared.followUser(uid: userID) { success in
            completion(success)
        }
    }
    
    func unfollowUser(completion: @escaping (Bool) -> Void) {
        guard let userID = user.value?.userID else {
            return
        }
        FollowService.shared.unfollowUser(uid: userID) { success in
            completion(success)
        }
    }
}
