//
//  ImageService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 21.03.2024.
//

import Foundation
import SDWebImage
import UIKit.UIImage
typealias URLString = String

final class ImageService: Sendable {

    static let shared = ImageService()

    func getImage(for urlString: URLString?) async throws -> UIImage? {
        guard let urlString = urlString,
              let url = URL(string: urlString)
        else {
            return nil
        }

        if let image = SDImageCache.shared.imageFromCache(forKey: urlString) {
            return image
        } else {
            return try await downloadImage(for: url)
        }
    }

    func getImage(for urlString: URLString?, completion: @escaping (Result<UIImage?, Error>) -> Void) {
        guard let urlString = urlString,
              let url = URL(string: urlString)
        else {
            return
        }
        SDWebImageManager.shared.loadImage(with: url, progress: .none) { image, _, error, _, _, _ in
            if error != nil {
                completion(.failure(ServiceError.couldntLoadData))
                return
            }
            completion(.success(image))
        }
    }

    private func downloadImage(for url: URL?) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            SDWebImageManager.shared.loadImage(with: url, progress: .none) { image, _, error, _, _, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let image = image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: ServiceError.unexpectedError)
                }
            }
        }
    }
}
