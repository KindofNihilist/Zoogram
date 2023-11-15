//
//  CommentsListFactory.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 24.05.2023.
//

import UIKit

class CommentListFactory {

    private var tableView: UITableView

    var sections = [TableSectionController]()

    private var postSection: PostSection?

    private var captionSection: CaptionSection?

    private var commentsSection: CommentSection!

    private let delegate: CommentsTableViewActionsProtocol

    private let shouldShowRelatedPost: Bool

    init(for tableView: UITableView, shouldShowRelatedPost: Bool, delegate: CommentsTableViewActionsProtocol) {
        self.tableView = tableView
        self.delegate = delegate
        self.shouldShowRelatedPost = shouldShowRelatedPost
    }

    func buildSections(for viewModel: CommentsTableViewVM){

        if shouldShowRelatedPost {
            let postController = createPostController(postViewModel: viewModel.postViewModel)
            postSection = PostSection(sectionHolder: tableView, cellControllers: [postController], sectionIndex: 0)
            sections.append(postSection!)
        } else {
            if let caption = CommentViewModel.createPostCaptionForCommentArea(with: viewModel.postViewModel) {
                let captionController = CommentCellController(viewModel: caption, isAPostCaption: true, delegate: self.delegate)
                captionSection = CaptionSection(sectionHolder: tableView, cellControllers: [captionController], sectionIndex: 0)
                sections.append(captionSection!)
            }
        }

        let commentsControllers = viewModel.comments.map { commentViewModel in
            CommentCellController(viewModel: commentViewModel, delegate: self.delegate)
        }

        commentsSection = CommentSection(sectionHolder: tableView, cellControllers: commentsControllers, sectionIndex: 1)
        sections.append(commentsSection!)
    }

    func createPostController(postViewModel: PostViewModel) -> PostCellController {
        return PostCellController(viewModel: postViewModel, delegate: self.delegate)
    }

    func getCommentSectionIndex() -> SectionIndex {
        return commentsSection.sectionIndex
    }

    func insertComment(with comment: CommentViewModel, at indexPath: IndexPath, completion: @escaping () -> Void) {
        let cellController = CommentCellController(viewModel: comment, delegate: self.delegate)
        print("Inserting new comment: \(comment.commentText)")
        commentsSection.insertCell(with: cellController, at: indexPath.row)
        completion()
    }

    func deleteComment(at indexPath: IndexPath) {
        commentsSection.removeCellController(at: indexPath)
        tableView.performBatchUpdates {
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}
