//
//  ImageService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 21.03.2024.
//

import Foundation
import SDWebImage

typealias URLString = String

class ImageService {

    static let shared = ImageService()

    func getImage(for urlString: String, completion: @escaping(Result<UIImage, Error>) -> Void) {

        let url = URL(string: urlString)
        
        SDWebImageManager.shared.loadImage(with: url, progress: .none) { downloadedImage, _, error, _, _, _ in
            if let error = error {
                completion(.failure(ServiceError.couldntLoadData))
                print(error)
                return
            } else if let image = downloadedImage {
                completion(.success(image))
            } else {
                completion(.failure(ServiceError.unexpectedError))
            }
        }
    }
}
