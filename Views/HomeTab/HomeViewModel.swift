//
//  HomeViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 16.10.2022.
//

import UIKit
import Firebase

class HomeViewModel {
    
    var followersRef: DatabaseReference!
    var followersSnap: DataSnapshot!

    var posts: Observable<[UserPost]> = Observable([])
    
    var lastObtainedPostKey = ""
    var isPaginating = false
    
    func refreshTheFeed(completion: @escaping ([UserPost]) -> Void) {
        getUserFeedPosts { posts in
            completion(posts)
        }
    }
    
    func getUserFeedPosts(completion: @escaping ([UserPost]) -> Void) {
        print("getUserFeedPosts called")
        self.posts.value?.removeAll()
        HomeFeedService.shared.getPostsForTimeline { posts, lastObtainedPostKey in
            self.posts.value?.append(contentsOf: posts)
            self.lastObtainedPostKey = lastObtainedPostKey
            print("Downloaded feed posts with last post key: \(lastObtainedPostKey)")
            completion(posts)
        }
    }
    
    func getMoreUserFeedPosts(completion: @escaping ([UserPost]) -> Void) {
        guard lastObtainedPostKey != "" else {
            return
        }
        
        isPaginating = true
        
        HomeFeedService.shared.getMorePostsForTimeline(after: lastObtainedPostKey) { posts, lastObtainedPostKey in
            print("Prev last post key:", self.lastObtainedPostKey)
            print("Last downloaded post key:", lastObtainedPostKey)
            print("Got more posts with last post key: \(lastObtainedPostKey)")
            guard lastObtainedPostKey != self.lastObtainedPostKey else {
                print("Hit the end of user posts")
                return
            }
            self.lastObtainedPostKey = lastObtainedPostKey
            self.posts.value?.append(contentsOf: posts)
            self.isPaginating = false
            completion(posts)
        }
    }
    
}
