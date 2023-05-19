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
        case failedToDeletePhoto
    }

    typealias APICallResult = Result<URL, StorageManagerError>

    typealias APICallNoValueResult = Result<Void, StorageManagerError>

    typealias ResultBlock = (APICallResult) -> Void

    typealias CompletionBlockWithoutValue = (APICallNoValueResult) -> Void

    func uploadUserProfilePhoto(for userID: String, with image: UIImage, fileName: String, completion: @escaping ResultBlock) {
        guard let data = image.pngData() else {
            return
        }
        let storagePath = "ProfilePictures/\(userID)/\(fileName)"
        print(storagePath)

        storage.child(storagePath).putData(data, metadata: nil) { metadata, error in
            guard error == nil else {
                print(error?.localizedDescription as Any)
                completion(.failure(.failedToUpload))
                return
            }
            self.storage.child(storagePath).downloadURL { url, error in
                guard let url = url else {
                    print(error?.localizedDescription as Any)
                    completion(.failure(.failedToGetDownloadURL))
                    return
                }
                completion(.success(url))
            }
        }
    }


    func uploadPostPhoto(photo: UIImage, fileName: String, progressUpdate: @escaping (Progress?) -> Void, completion: @escaping ResultBlock) {
        guard let imageData = photo.pngData() else {
            return
        }
        let userID = AuthenticationManager.shared.getCurrentUserUID()
        let storagePath = "UserPhotoPosts/\(userID)/\(fileName)"

        let uploadTask = storage.child(storagePath).putData(imageData) { metadata, error in
            guard error == nil else {
                print(error?.localizedDescription as Any)
                completion(.failure(.failedToUpload))
                return
            }

            self.storage.child(storagePath).downloadURL { result in
                switch result {
                case .failure(let error):
                    print(error.localizedDescription)
                    completion(.failure(.failedToGetDownloadURL))

                case .success(let url):
                    completion(.success(url))
                }
            }
        }

        uploadTask.observe(.progress) { snapshot in
            progressUpdate(snapshot.progress)
        }
    }



    func deletePostPhoto(photoURL: String, completion: @escaping CompletionBlockWithoutValue) {
        let path = storage.storage.reference(forURL: photoURL).fullPath

        storage.child(path).delete { error in
            guard error == nil else {
                completion(.failure(.failedToDeletePhoto))
                return
            }
            completion(.success(Void()))
        }
    }

    func getDownloadURL(for path: String, completion: @escaping ResultBlock) {
        let reference = storage.child(path)
        reference.downloadURL { result in
            switch result {

            case .success(let url):
                completion(.success(url))

            case .failure(let error):
                print(error.localizedDescription)
                completion(.failure(.failedToGetDownloadURL))
            }
        }
    }
}
