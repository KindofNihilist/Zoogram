//
//  Errors.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 20.03.2024.
//

import Foundation

enum ServiceError: LocalizedError {
    case jsonParsingError
    case snapshotCastingError
    case unexpectedError
    case couldntLoadUserData
    case couldntUploadUserData
    case couldntLoadData
    case couldntUploadData
    case couldntUploadPost
    case couldntDeletePost
    case couldntCompleteTheSearch
    case couldntLoadPosts
    case couldntCompleteTheAction
    case couldntPostAComment
    case couldntDeleteAComment
    case couldntDeleteData
    case couldntLoadBookmarks

    var errorDescription: String? {
        switch self {
        case .jsonParsingError: return String(localized: "Uh-oh, something went wrong")
        case .snapshotCastingError: return String(localized: "Uh-oh, something went wrong")
        case .unexpectedError: return String(localized: "Uh-oh, something went wrong")
        case .couldntLoadUserData: return String(localized: "Couldn't load user data")
        case .couldntUploadUserData: return String(localized: "Couldn't upload profile changes")
        case .couldntLoadData: return String(localized: "Couldn't load data")
        case .couldntUploadData: return String(localized: "Couldn't upload data")
        case .couldntUploadPost: return String(localized: "Couldn't upload your post, please try again later.")
        case .couldntDeletePost: return String(localized: "Couldn't delete post")
        case .couldntCompleteTheSearch: return String(localized: "Couldn't complete the search")
        case .couldntLoadPosts: return String(localized: "Couldn't load posts")
        case .couldntCompleteTheAction: return String(localized: "Couldn't complete the action")
        case .couldntPostAComment: return String(localized: "Couldn't post a comment")
        case .couldntDeleteAComment: return String(localized: "Couldn't delete a comment")
        case .couldntDeleteData: return String(localized: "Couldn't delete data")
        case .couldntLoadBookmarks: return String(localized: "Couldn't load bookmarks")
        }
    }
}
