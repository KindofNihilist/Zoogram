//
//  ImageServiceMock.swift
//  ZoogramTests
//
//  Created by Artem Dolbiiev on 10.07.2024.
//

import UIKit.UIImage
@testable import Zoogram

final class ImageServiceMock: ImageServiceProtocol {

    func getImage(for urlString: Zoogram.URLString?) async throws -> UIImage? {
        return UIImage()
    }

    func getImage(for urlString: Zoogram.URLString?, completion: @escaping (Result<UIImage?, any Error>) -> Void) {
        completion(.success(UIImage()))
    }
}
