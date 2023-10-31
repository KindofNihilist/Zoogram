//
//  CommentsListFactory.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 24.05.2023.
//

import UIKit

class CommentListFactory {

    internal var tableView: UITableView

    private var postSection: PostSection?

    private var captionSection: CaptionSection?

    private var commentsSection: CommentSection!

    private let delegate: CommentsTableViewActionsProtocol

    private var comments: [CommentViewModel]

    private let post: PostViewModel

    private let shouldShowRelatedPost: Bool

    init(post: PostViewModel, comments: [CommentViewModel], shouldShowRelatedPost: Bool, tableView: UITableView, delegate: CommentsTableViewActionsProtocol) {
        self.post = post
        self.comments = comments
        self.tableView = tableView
        self.delegate = delegate
        self.shouldShowRelatedPost = shouldShowRelatedPost
    }

    func buildSections() -> [TableSectionController] {
        var sections = [TableSectionController]()

        if shouldShowRelatedPost {
            let postController = createPostController(postViewModel: post)
            postSection = PostSection(sectionHolder: tableView, cellControllers: [postController])
            postSection?.sectionIndex = 0
            sections.append(postSection!)
        } else {
            if let caption = CommentViewModel.createPostCaptionForCommentArea(with: self.post) {
                let captionController = CommentCellController(viewModel: caption, delegate: self.delegate)
                captionSection = CaptionSection(sectionHolder: tableView, cellControllers: [captionController])
                captionSection?.sectionIndex = 0
                sections.append(captionSection!)
            }
        }

        let commentsControllers = self.comments.map { commentViewModel in
            CommentCellController(viewModel: commentViewModel, delegate: self.delegate)
        }

        commentsSection = CommentSection(sectionHolder: tableView, cellControllers: commentsControllers)
        sections.append(commentsSection!)
        return sections
    }

    func getCommentSectionRect() -> CGRect? {
        guard let commentSectionIndex = commentsSection.sectionIndex else {
            return nil
        }
        return tableView.rect(forSection: commentSectionIndex)
//        if let postSection = postSection {
//            let postRectangle = tableView.rect(forSection: postSection.sectionIndex)
//            return postRectangle.maxY
//        } else if let captionSection = captionSection {
//            let captionRectangle = tableView.rect(forSection: captionSection.sectionIndex)
//            return captionRectangle.maxY
//        } else {
//            let commentsRectange = tableView.rect(forSection: commentsSection.sectionIndex)
//            return commentsRectange.minY
//        }
    }

    func createPostController(postViewModel: PostViewModel) -> PostCellController {
        return PostCellController(viewModel: postViewModel, delegate: self.delegate)
    }

    func getCommentSectionIndex() -> SectionIndex? {
        return commentsSection.sectionIndex
    }

    func removeCommentCell(at indexPath: IndexPath, with animation: UITableView.RowAnimation) {
        self.comments.remove(at: indexPath.row)
        commentsSection.removeCell(at: indexPath, in: self.tableView)
    }

    func insertCommentCell(with comment: CommentViewModel, with animation: UITableView.RowAnimation, completion: @escaping () -> Void) {
        guard let commentSectionIndex = commentsSection.sectionIndex else {
            return
        }
        self.comments.append(comment)
        let commentController = CommentCellController(viewModel: comment, delegate: self.delegate)
        let commentSectionIndexPath = IndexPath(row: 0, section: commentSectionIndex)
        commentsSection.insertCell(with: commentController, at: commentSectionIndexPath, in: self.tableView)
        completion()
    }
}
