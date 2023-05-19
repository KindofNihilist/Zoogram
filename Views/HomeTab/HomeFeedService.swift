//
//  HomeFeedService.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 09.05.2023.
//

import Foundation

protocol HomeFeedService: PostsService {
    func makeANewPost(post: UserPost, progressUpdateCallback: @escaping (Progress?) -> Void, completion: @escaping (Result<Void, Error>) -> Void)
}
