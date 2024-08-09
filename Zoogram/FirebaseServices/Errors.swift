//
//  Errors.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 20.03.2024.
//

import Foundation

enum ServiceError: LocalizedError {
    case authorizationError

    case snapshotCastingError
    case unexpectedError
    case couldntLoadUserData
    case couldntLoadComments
    case couldntLoadData
    case couldntLoadPosts
    case couldntLoadPost
    case couldntLoadBookmarks
    case couldntUploadUserData
    case couldntUploadData
    case couldntUploadPost
    case couldntDeletePost
    case couldntDeleteAComment
    case couldntDeleteData
    case couldntCompleteTheSearch
    case couldntCompleteTheAction
    case couldntPostAComment
    case invalidURL
    case jsonParsingError

    var errorDescription: String? {
        switch self {
        case .authorizationError: return String(localized: "Authorization Error")
        case .unexpectedError: return String(localized: "Uh-oh, something went wrong")
        case .couldntLoadUserData: return String(localized: "Couldn't load user data")
        case .couldntLoadData: return String(localized: "Couldn't load data")
        case .couldntLoadPosts: return String(localized: "Couldn't load posts")
        case .couldntLoadPost: return String(localized: "Couldn't load post")
        case .couldntLoadBookmarks: return String(localized: "Couldn't load bookmarks")
        case .couldntLoadComments: return String(localized: "Couldn't load comments")
        case .couldntUploadUserData: return String(localized: "Couldn't upload profile changes")
        case .couldntUploadData: return String(localized: "Couldn't upload data")
        case .couldntUploadPost: return String(localized: "Couldn't upload your post, please try again later.")
        case .couldntCompleteTheSearch: return String(localized: "Couldn't complete the search")
        case .couldntCompleteTheAction: return String(localized: "Couldn't complete the action")
        case .couldntPostAComment: return String(localized: "Couldn't post a comment")
        case .couldntDeletePost: return String(localized: "Couldn't delete post")
        case .couldntDeleteAComment: return String(localized: "Couldn't delete a comment")
        case .couldntDeleteData: return String(localized: "Couldn't delete data")
        case .invalidURL: return String(localized: "Invalid URL")
        case .snapshotCastingError: return String(localized: "Uh-oh, something went wrong")
        case .jsonParsingError: return String(localized: "Uh-oh, something went wrong")
        }
    }
}
