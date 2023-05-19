//
//  PostWithCommentsViewModel.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 17.05.2023.
//

import Foundation

class PostWithCommentsViewModel {

    private let service: PostWithCommentsService

    var hasInitialzied = Observable(false)

    private var postViewModel: PostViewModel

    private var comments = [CommentViewModel]()

    init(post: UserPost, service: PostWithCommentsService) {
        self.service = service
        self.postViewModel = PostViewModel(post: post)
        fetchDataOnInit(for: post)
    }

    private func fetchDataOnInit(for post: UserPost) {
        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        service.getAdditionalPostData(for: post) { post in
            self.postViewModel = PostViewModel(post: post)
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        service.getComments { comments in
            self.comments = comments.map({ comment in
                CommentViewModel(comment: comment)
            })
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            self.hasInitialzied.value = true
        }
    }

    func getNumberOfRowsIn(section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return comments.count
        }
    }

    func getPostViewModel() -> PostViewModel {
        return self.postViewModel
    }

    func getComment(for indexPath: IndexPath) -> CommentViewModel {
        return comments[indexPath.row]
    }

    func deleteThisPost(completion: @escaping () -> Void) {
        service.deletePost(postModel: self.postViewModel) {
            completion()
        }
    }

    func likeThisPost(completion: @escaping (LikeState) -> Void) {
        self.service.likePost(postID: postViewModel.postID,
                              likeState: postViewModel.likeState,
                              postAuthorID: postViewModel.author.userID) { likeState in
            self.postViewModel.likeState = likeState
            completion(likeState)
        }
    }

    func bookmarkThisPost(completion: @escaping (BookmarkState) -> Void) {
        self.service.bookmarkPost(postID: postViewModel.postID,
                                  authorID: postViewModel.author.userID,
                                  bookmarkState: postViewModel.bookmarkState) { bookmarkState in
            self.postViewModel.bookmarkState = bookmarkState
            completion(bookmarkState)
        }
    }
}
