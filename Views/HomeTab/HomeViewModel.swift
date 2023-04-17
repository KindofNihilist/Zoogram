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

    var posts: Observable<[PostViewModel]> = Observable([])
    
    var lastObtainedPostKey = ""
    var isPaginating = false
    
//    func refreshTheFeed(completion: @escaping ([UserPost]) -> Void) {
//        getUserFeedPosts { posts in
//            completion(posts)
//        }
//    }
}
