//
//  CommentsTableView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 22.05.2023.
//

import UIKit

protocol CommentsTableViewProtocol: CommentAccessoryViewProtocol, CommentCellProtocol {}

class CommentsTableView: UITableView {

    let isCaptionless: Bool
    let postCaption: CommentViewModel?

    var keyboardAccessoryView: CommentAccessoryView = {
        let commentAccessoryView = CommentAccessoryView()
        return commentAccessoryView
    }()

    init(postCaption: CommentViewModel?) {
        self.postCaption = postCaption
        self.isCaptionless = postCaption == nil ? true : false
        super.init(frame: CGRect())

        self.backgroundColor = .systemBackground
        self.translatesAutoresizingMaskIntoConstraints = false
        self.keyboardDismissMode = .interactive
        self.rowHeight = UITableView.automaticDimension
        self.estimatedRowHeight = UITableView.automaticDimension
        self.estimatedSectionFooterHeight = UITableView.automaticDimension
        self.estimatedSectionHeaderHeight = UITableView.automaticDimension
        self.allowsSelection = false
        self.separatorStyle = .none
        self.register(CommentTableViewCell.self, forCellReuseIdentifier: CommentTableViewCell.identifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var inputAccessoryView: UIView? {
        return keyboardAccessoryView
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    func scrollToTheLastRow() {
        let lastRow = (self.numberOfRows(inSection: isCaptionless ? 0 : 1) - 1)
        guard lastRow >= 1 else {
            return
        }
        self.scrollToRow(at: IndexPath(row: lastRow, section: isCaptionless ? 0 : 1), at: .bottom, animated: true)
    }

    @objc func keyboardWillAppear() {
        if keyboardAccessoryView.isEditing {
            self.keyboardAccessoryView.intrinsicHeight = keyboardAccessoryView.accessoryViewHeight
            scrollToTheLastRow()
        }
    }

    @objc func keyboardWillDisappear() {
        print("keyboardWillDisappear triggered")
        self.keyboardAccessoryView.intrinsicHeight = keyboardAccessoryView.accessoryViewHeight + self.safeAreaInsets.bottom
    }
}
