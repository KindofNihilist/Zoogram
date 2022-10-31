//
//  HomeViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 16.10.2022.
//

import UIKit

class HomeViewModel {
    
    private var usersFollowed = [String]() //Contains ids of followed users
    
    private var postIDS = [String]()

    private var posts = [UserPost]()
    
    func getFollowedUsers() {
        let userUID = AuthenticationManager.shared.getCurrentUserUID()
    }
    
    
    
    
    
}
