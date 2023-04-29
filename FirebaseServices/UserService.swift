//
//  UserService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.12.2022.
//

import Foundation
import FirebaseDatabase
import SDWebImage

class UserService {
    
    static let shared = UserService()
    
    private let databaseRef = Database.database(url: "https://catogram-58487-default-rtdb.europe-west1.firebasedatabase.app").reference()
    
    typealias IsSuccessful = Bool
    
    func insertNewUser(with user: ZoogramUser, completion: @escaping (IsSuccessful) -> Void) {
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
    
                        decodedUser.followStatus = followStatus
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
    
    func observeUser(for userID: String, completion: @escaping (ZoogramUser) -> Void) {
        
        let path = storageKeys.users.rawValue + userID
        
        self.databaseRef.child(path).observe( .value) { snapshot in
            
            guard let value = snapshot.value as? [String: Any] else {
                return
            }
            
            do {
                let json = try JSONSerialization.data(withJSONObject: value as Any)
                let decodedUser = try JSONDecoder().decode(ZoogramUser.self, from: json)
                FollowService.shared.checkFollowStatus(for: userID) { followStatus in
                    decodedUser.followStatus = followStatus
                    completion(decodedUser)
                }
            } catch {
                print(error)
            }
            
        }
    }
    
    func getUser(for userID: String, completion: @escaping (ZoogramUser) -> Void) {
        
        let path = storageKeys.users.rawValue + userID
        
        self.databaseRef.child(path).observeSingleEvent(of: .value) { snapshot in
            
            guard let value = snapshot.value as? [String: Any] else {
                return
            }
            
            do {
                let json = try JSONSerialization.data(withJSONObject: value as Any)
                let decodedUser = try JSONDecoder().decode(ZoogramUser.self, from: json)
                FollowService.shared.checkFollowStatus(for: userID) { followStatus in
                    decodedUser.followStatus = followStatus
                    completion(decodedUser)
                }
            } catch {
                print(error)
            }
            
        }
    }
    
    
    
    func getUserProfilePicture(for userID: String, completion: @escaping (UIImage?) -> Void) {
        let path = storageKeys.users.rawValue + userID + "/profilePhotoURL"
        let groupDispatch = DispatchGroup()
        var imageURL: URL?
        
        groupDispatch.enter()
        self.databaseRef.child(path).observeSingleEvent(of: .value) { snapshot in
            guard let snapshotValue = snapshot.value as? String else {
                print(snapshot.value)
                print("Wrong value")
                return
            }
            imageURL = URL(string: snapshotValue)
            groupDispatch.leave()
        }
        
        groupDispatch.notify(queue: .main) {
            SDWebImageManager.shared.loadImage(with: imageURL, progress: .none) { image, _, _, _, _, _ in
                completion(image)
            }
        }
    }
    
    func changeHasPostsStatus(hasPostsStatus: Bool, completion: @escaping () -> Void) {
        let userID = AuthenticationManager.shared.getCurrentUserUID()
        
        let databaseKey = "Users/\(userID)/hasPosts"
        
        print("inside changeHasPostsStatus method")
        databaseRef.child(databaseKey).setValue(hasPostsStatus) { error, _ in
            if error == nil {
                // succeeded
                print("changed hasPosts status")
                completion()
            } else {
                // failed
                print("failed to change hasPosts status: \(error)")
                completion()
            }
        }
    }
    
    typealias IsAvailable = Bool
    
    func checkIfUsernameIsAvailable(username: String, completion: @escaping (IsAvailable) -> Void) {
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
                self?.databaseRef.child("Users/\(uid)").updateChildValues(["profilePhotoURL" : pictureURL.absoluteString])
                AuthenticationManager.shared.updateUserProfileURL(profilePhotoURL: pictureURL) {
                    completion()
                }
                return
                
            case .failure(let error):
                print(error)
            }
        }
    }
}
