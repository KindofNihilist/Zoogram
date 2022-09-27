//
//  StorageManager.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//
import FirebaseStorage
import Foundation

public class StorageManager {
    
    static let shared = StorageManager()

    private let storage = Storage.storage(url: "gs://catogram-58487.appspot.com/").reference()
    public enum StorageManagerError: Error {
        case failedToDownload
        case failedToUpload
        case failedToGetDownloadURL
    }
    
    public func uploadUserProfilePhoto(for userID: String, with image: UIImage, fileName: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let data = image.pngData() else {
            return
        }
        let storagePath = "ProfilePictures/\(userID)/\(fileName)"
        print(storagePath)
        storage.child(storagePath).putData(data, metadata: nil) { metadata, error in
            guard error == nil else {
                print("Failed to upload data to Firebase storage")
                completion(.failure(error!))
                return
            }
            self.storage.child(storagePath).downloadURL { url, error in
                guard let url = url else {
                    print("Could not retrieve photo url")
                    completion(.failure(error!))
                    return
                }
                let urlString = url.absoluteString
                print("download url retrieved: \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
    
    public func uploadUserPhotoPost(model: UserPost, completion: @escaping (Result<URL, Error>) -> Void) {
         
    }
    
    public func downloadURL(for path: String, completion: @escaping (Result<URL, StorageManagerError>) -> Void) {
        let reference = storage.child(path)
        reference.downloadURL { url, error in
            guard let url = url, error == nil else {
                completion(.failure(.failedToGetDownloadURL))
                return
            }
            completion(.success(url))
        }
    }
}
