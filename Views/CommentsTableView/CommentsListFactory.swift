//
//  CommentsListFactory.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 24.05.2023.
//

import UIKit

class CommentListFactory: TableViewFactory {

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

    func buildSections() -> [TableViewSectionBuilder] {
        var sections = [TableViewSectionBuilder]()

        if shouldShowRelatedPost {
            let postBuilder = createPostBuilder(postViewModel: post)
            postSection = PostSection(builders: [postBuilder], delegate: self)
            sections.append(postSection!)
        } else {
            if let caption = CommentViewModel.createPostCaptionForCommentArea(with: self.post) {
                let captionBuilder = CommentTableViewCellBuilder(viewModel: caption, delegate: self.delegate)
                captionSection = CaptionSection(builders: [captionBuilder], delegate: self)
                sections.append(captionSection!)
            }
        }

        let commentsBuilders = self.comments.map { commentViewModel in
            CommentTableViewCellBuilder(viewModel: commentViewModel, delegate: self.delegate)
        }

        commentsSection = CommentSection(builders: commentsBuilders, delegate: self)
        sections.append(commentsSection!)

        return sections
    }

    func registerCells() {
        tableView.register(CommentTableViewCell.self, forCellReuseIdentifier: CommentTableViewCell.identifier)
        tableView.register(PostTableViewCell.self, forCellReuseIdentifier: PostTableViewCell.identifier)
    }

    func createPostBuilder(postViewModel: PostViewModel) -> PostTableViewCellBuilder {
        return PostTableViewCellBuilder(viewModel: postViewModel, delegate: self.delegate)
    }

    func getCommentSectionIndex() -> SectionIndex {
        return commentsSection.sectionIndex
    }

    func removeCommentCell(at indexPath: IndexPath, with animation: UITableView.RowAnimation) {
        self.comments.remove(at: indexPath.row)
        commentsSection.removeCell(at: indexPath, in: self.tableView, with: animation)
    }

    func insertCommentCell(with comment: CommentViewModel, with animation: UITableView.RowAnimation, completion: @escaping () -> Void) {
        self.comments.append(comment)
        let commentBuilder = CommentTableViewCellBuilder(viewModel: comment, delegate: self.delegate)
        commentsSection.insertCell(for: commentBuilder, at: IndexPath(row: 0, section: commentsSection.sectionIndex), in: tableView, with: animation)
        completion()
    }
}

extension CommentListFactory: SectionManager {
    func getSectionIndex() -> SectionIndex {
        if postSection != nil || captionSection != nil {
            return 1
        } else {
            return 0
        }
    }
}
