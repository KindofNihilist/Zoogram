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
    
    
    var username: String = ""
    var name: String = ""
    var bio: String = ""
    var profilePhoto = UIImage()
    var postsCount = ""
    var followersCount = ""
    var followingCount = ""
    var userID: String!
    var userPosts = [UserPost]()
    
//    func initializeViewModel(userID: String, completion: @escaping () -> Void) {
//        getUserDataFor(userID: userID) {
//            self.getUserPosts() {
//                self.hasInitialized = true
//                completion()
//            }
//        }
//
//        getFollowersFollowingNumber(userID: userID)
//
//    }
    
    init(for uid: String, followStatus: FollowStatus, isUserProfile: Bool) {
        self.isFollowed = followStatus
        self.isUserProfile = isUserProfile
        
        let dispatchGroup = DispatchGroup()
        print("Initialize for UID: \(uid)")
        dispatchGroup.enter()
        getUserDataFor(userID: uid) {
            print("got data")
            self.getUserPosts(for: uid) {
                print("got posts")
                self.getFollowersFollowingNumber(userID: uid) {
                    print("got followers and followed")
                    dispatchGroup.leave()
                    self.isInitialized = true
                }
            }
        }
        
        
        
        dispatchGroup.notify(queue: .main) {
            NotificationCenter.default.post(name: Notification.Name("ReceivedData"), object: nil)
        }
    }
    
    func getFollowersFollowingNumber(userID: String, completion: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        DatabaseManager.shared.getFollowersNumber(for: userID) { followersCount in
            dispatchGroup.enter()
            self.followersCount = "\(followersCount)"
            dispatchGroup.leave()
        }
        DatabaseManager.shared.getFollowingNumber(for: userID) { followingCount in
            dispatchGroup.enter()
            self.followingCount = "\(followingCount)"
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: .main) {
            completion()
        }
        
    }
    
    
    func getUserDataFor(userID: String, completion: @escaping () -> Void) {
        DatabaseManager.shared.getUser(for: userID) { [weak self] user in
    
            self?.userID = user.userID
            self?.username = user.username
            self?.name = user.name
            self?.bio = user.bio ?? ""
            self?.postsCount = "\(user.posts)"
            print(user.self)
            SDWebImageManager.shared.loadImage(with: URL(string: user.profilePhotoURL), progress: .none) { image, _, _, _, _, _ in
                if let image = image {
                    self?.profilePhoto = image
                    completion()
                }
            }
        }
    }
    
    func getUserPosts(for uid: String, completion: @escaping () -> Void) {
        DatabaseManager.shared.getPosts(for: uid) { posts, lastObtainedPostKey in
            self.userPosts.append(contentsOf: posts)
            self.lastObtainedPostKey = lastObtainedPostKey
            print("Downloaded initials posts with last post key: \(lastObtainedPostKey)")
            completion()
        }
    }
    
    func getMoreUserPosts(completion: @escaping ([UserPost]) -> Void) {
        guard let userID = userID,
        lastObtainedPostKey != "" else {
            return
        }
        
        isPaginating = true
        
        DatabaseManager.shared.getMorePosts(after: lastObtainedPostKey, for: userID) { posts, lastDownloadedPostKey in
            print("Prev last post key:", self.lastObtainedPostKey)
            print("Last downloaded post key:", lastDownloadedPostKey)
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
    
    func followUser(completion: @escaping (Bool) -> Void) {
        DatabaseManager.shared.followUser(uid: userID) { success in
            completion(success)
        }
    }
    
    func unfollowUser(completion: @escaping (Bool) -> Void) {
        DatabaseManager.shared.unfollowUser(uid: userID) { success in
            completion(success)
        }
    }
}
