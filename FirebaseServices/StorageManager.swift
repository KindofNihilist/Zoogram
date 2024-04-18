//
//  StorageManager.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//
import FirebaseStorage
import Foundation

protocol StorageManagerProtocol {
    typealias APICallResult = Result<URL, Error>
    typealias ResultBlock = (APICallResult) -> Void
    typealias CompletionBlockWithoutValue = (VoidResult) -> Void

    func uploadUserProfilePhoto(for userID: String, with image: UIImage, fileName: String, completion: @escaping ResultBlock)
    func uploadPostPhoto(photo: UIImage, fileName: String, progressUpdate: @escaping (Progress?) -> Void, completion: @escaping ResultBlock)
    func deletePostPhoto(photoURL: String, completion: @escaping CompletionBlockWithoutValue)
    func getDownloadURL(for path: String, completion: @escaping ResultBlock)
}

class StorageManager: StorageManagerProtocol {

    static let shared = StorageManager()

    private let storageReference = Storage.storage(url: "gs://catogram-58487.appspot.com/").reference()

    init() {
        storageReference.storage.maxUploadRetryTime = 5
        storageReference.storage.maxOperationRetryTime = 5
        storageReference.storage.maxDownloadRetryTime = 5
    }

    func uploadUserProfilePhoto(for userID: String, with image: UIImage, fileName: String, completion: @escaping ResultBlock) {
        guard let data = image.jpegData(compressionQuality: 1) else {
            return
        }
        let storagePath = "ProfilePictures/\(userID)/\(fileName)"

        storageReference.child(storagePath).putData(data, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadData))
            } else {
                self.storageReference.child(storagePath).downloadURL { url, error in
                    if let error = error {
                        completion(.failure(ServiceError.couldntLoadData))
                        return
                    } else if let url = url {
                        completion(.success(url))
                    }
                }
            }
        }
    }

    func uploadPostPhoto(photo: UIImage, fileName: String, progressUpdate: @escaping (Progress?) -> Void, completion: @escaping ResultBlock) {
        guard let imageData = photo.jpegData(compressionQuality: 1),
              let userID = AuthenticationService.shared.getCurrentUserUID()
        else {
            return
        }
        let storagePath = "UserPhotoPosts/\(userID)/\(fileName)"

        let uploadTask = storageReference.child(storagePath).putData(imageData) { _, error in
            if let error = error {
                completion(.failure(ServiceError.couldntUploadPost))
                return
            } else {
                self.storageReference.child(storagePath).downloadURL { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(ServiceError.couldntUploadPost))
                    case .success(let url):
                        completion(.success(url))
                    }
                }
            }
        }
        uploadTask.observe(.progress) { snapshot in
            progressUpdate(snapshot.progress)
            if let error = snapshot.error {
                completion(.failure(ServiceError.couldntUploadPost))
                uploadTask.cancel()
            }
        }
    }

    func deletePostPhoto(photoURL: String, completion: @escaping CompletionBlockWithoutValue) {
        let path = storageReference.storage.reference(forURL: photoURL).fullPath

        storageReference.child(path).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success)
            }
        }
    }

    func getDownloadURL(for path: String, completion: @escaping ResultBlock) {
        let reference = storageReference.child(path)
        reference.downloadURL { result in
            switch result {

            case .success(let url):
                completion(.success(url))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
