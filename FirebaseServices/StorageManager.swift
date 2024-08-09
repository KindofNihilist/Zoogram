//
//  StorageManager.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//
@preconcurrency import FirebaseStorage
import Foundation

protocol StorageManagerProtocol: Sendable {
    func uploadUserProfilePhoto(for userID: String, with image: UIImage, fileName: String) async throws -> URL
    func uploadPostPhoto(photo: UIImage, fileName: String, progressUpdate: @escaping (Progress?) -> Void) async throws -> URL
    func deletePostPhoto(photoURL: String) async throws
    func getDownloadURL(for path: String) async throws -> URL
}

final class StorageManager: StorageManagerProtocol {

    static let shared = StorageManager()

    private let storageReference = Storage.storage(url: "gs://catogram-58487.appspot.com/").reference()

    init() {
        storageReference.storage.maxUploadRetryTime = 5
        storageReference.storage.maxOperationRetryTime = 5
        storageReference.storage.maxDownloadRetryTime = 5
    }

    func uploadUserProfilePhoto(for userID: String, with image: UIImage, fileName: String) async throws -> URL {
        guard let data = image.jpegData(compressionQuality: 1) else { throw ServiceError.unexpectedError }
        let storagePath = "ProfilePictures/\(userID)/\(fileName)"
        let query = storageReference.child(storagePath)

        do {
            _ = try await query.putDataAsync(data)
            let downloadURL = try await getDownloadURL(for: storagePath)
            return downloadURL
        } catch {
            throw ServiceError.couldntUploadUserData
        }
    }

    func uploadPostPhoto(photo: UIImage, fileName: String, progressUpdate: @escaping (Progress?) -> Void) async throws -> URL {
        guard let imageData = photo.jpegData(compressionQuality: 1) else { throw ServiceError.unexpectedError }
        do {
            let userID =  try AuthenticationService.shared.getCurrentUserUID()
            let storagePath = "UserPhotoPosts/\(userID)/\(fileName)"
            _ = try await storageReference.child(storagePath).putDataAsync(imageData) { progress in
                progressUpdate(progress)
            }
            let downloadURL = try await storageReference.child(storagePath).downloadURL()
            return downloadURL
        } catch {
            throw ServiceError.couldntUploadPost
        }
    }

    func deletePostPhoto(photoURL: String) async throws {
        let path = storageReference.storage.reference(forURL: photoURL).fullPath
        do {
            try await storageReference.child(path).delete()
        } catch {
            throw ServiceError.couldntDeletePost
        }
    }

    func getDownloadURL(for path: String) async throws -> URL {
        let query = storageReference.child(path)
        let url = try await query.downloadURL()
        return url
    }
}
