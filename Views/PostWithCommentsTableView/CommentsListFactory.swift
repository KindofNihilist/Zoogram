//
//  CommentsListFactory.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 24.05.2023.
//

import UIKit

class CommentListFactory: TableViewFactory {

    private let delegate: CommentsTableViewActionsProtocol

    private let caption: CommentViewModel?

    private let comments: [CommentViewModel]

    private let post: PostViewModel?

    init(caption: CommentViewModel?, post: PostViewModel?, comments: [CommentViewModel], delegate: CommentsTableViewActionsProtocol) {
        self.post = post
        self.comments = comments
        self.delegate = delegate
        self.caption = caption
    }

    func buildSections() -> [TableViewSectionBuilder] {
        var sections = [TableViewSectionBuilder]()

        if let post = self.post {
            let postBuilder = createPostBuilder(postViewModel: post)
            let postSection = BaseSection(builders: [postBuilder])
            sections.append(postSection)
        } else if let caption = self.caption {
            let captionBuilder = CommentTableViewCellBuilder(viewModel: caption, delegate: self.delegate)
            let captionSection = BaseSection(builders: [captionBuilder])
            sections.append(captionSection)
        }

        var commentsBuilders = self.comments.map { commentViewModel in
            CommentTableViewCellBuilder(viewModel: commentViewModel, delegate: self.delegate)
        }

        let commentsSection = BaseSection(builders: commentsBuilders)
        sections.append(commentsSection)

        return sections
    }

    func createPostBuilder(postViewModel: PostViewModel) -> PostTableViewCellBuilder {
        return PostTableViewCellBuilder(viewModel: postViewModel, delegate: self.delegate)
    }

}
