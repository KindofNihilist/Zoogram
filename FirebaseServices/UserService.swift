//
//  UserService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.12.2022.
//

import Foundation
import FirebaseDatabase

class UserService {
    
    static let shared = UserService()
    
    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()
    
    func insertNewUser(with user: ZoogramUser, completion: @escaping (Bool) -> Void) {
        let userID = AuthenticationManager.shared.getCurrentUserUID()
        
        let userDictionary = user.createDictionary()
        
        let databaseKey = "Users/\(userID)"
        
        databaseRef.child(databaseKey).setValue(userDictionary) { error, _ in
            if error == nil {
                // succeeded
                print("succesfully inserted user")
                completion(true)
            } else {
                // failed
                print("failed to insert data: \(error)")
                completion(false)
            }
        }
    }
    
    func searchUserWith(username: String, completion: @escaping ([ZoogramUser]) -> Void) {
        
        let query = databaseRef.child("Users").queryOrdered(byChild: "username").queryStarting(atValue: username).queryEnding(atValue: "\(username)~")
        
        query.observeSingleEvent(of: .value) { snapshot in
            print(snapshot)
            
            var foundUsers = [ZoogramUser]()
            let dispatchGroup = DispatchGroup()
            
            for snapshotChild in snapshot.children {
                dispatchGroup.enter()
                guard let userSnapshot = snapshotChild as? DataSnapshot,
                      let userDictionary = userSnapshot.value as? [String: Any]
                else {
                    print("Couldn't convert snapshot to dictionary")
                    return
                }
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: userDictionary as Any)
                    let decodedUser = try JSONDecoder().decode(ZoogramUser.self, from: jsonData)
                    FollowService.shared.checkFollowStatus(for: decodedUser.userID) { followStatus in
    
                        decodedUser.isFollowed = followStatus
                        foundUsers.append(decodedUser)
                        dispatchGroup.leave()
                    }
                } catch {
                    print("Couldn't decode user")
                }
            }
            dispatchGroup.notify(queue: .main) {
                completion(foundUsers)
            }
        }
    }
    
    func getUser(for userID: String, completion: @escaping (ZoogramUser) -> Void) {
        
        let path = storageKeys.users.rawValue + userID
        
        self.databaseRef.child(path).observe( .value) { snapshot in
            
            guard let value = snapshot.value as? [String: Any] else {
                return
            }
            
            do {
                let json = try JSONSerialization.data(withJSONObject: value as Any)
                let decodedUser = try JSONDecoder().decode(ZoogramUser.self, from: json)
                FollowService.shared.checkFollowStatus(for: userID) { followStatus in
                    decodedUser.isFollowed = followStatus
                    completion(decodedUser)
                }
            } catch {
                print(error)
            }
            
        }
    }
    
    func checkIfUsernameIsAvailable(username: String, completion: @escaping (Bool) -> Void) {
        let query = databaseRef.child("Users").queryOrdered(byChild: "username").queryEqual(toValue: username)
        query.observe( .value) { snapshot in
            if snapshot.exists() {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    
    
    //MARK: User Profile edditing
    
    func updateUserProfile(with values: [String: Any], completion: @escaping () -> Void) {
        let uid = AuthenticationManager.shared.getCurrentUserUID()
        
        if !values.isEmpty {
            databaseRef.child("Users/\(uid)").updateChildValues(values)
            completion()
        }
    }
    
    func updateUserProfilePicture(newProfilePic: UIImage, completion: @escaping () -> Void = {}) {
        let uid = AuthenticationManager.shared.getCurrentUserUID()
        
        StorageManager.shared.uploadUserProfilePhoto(for: uid, with: newProfilePic, fileName: "\(AuthenticationManager.shared.getCurrentUserUID())_ProfilePicture.png") { [weak self] result in
            
            switch result {
                
            case .success(let pictureURL):
                self?.databaseRef.child("Users/\(uid)").updateChildValues(["profilePhotoURL" : pictureURL])
                completion()
                return
                
            case .failure(let error):
                print(error)
            }
        }
    }
}
