//
//  DiscoverViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 21.10.2022.
//

import Foundation

class DiscoverViewModel {
    
    var foundUsers = [ZoogramUser]()
    
    func searchUser(for input: String, completion: @escaping () -> Void ) {
        guard input != "" else {
            foundUsers = []
            completion()
            return
        }
        
        print("inside search user func")
        UserService.shared.searchUserWith(username: input) { users in
            print("Search results: ", users)
            self.foundUsers = users
            print(self.foundUsers)
            completion()
        }
    }
    
}
