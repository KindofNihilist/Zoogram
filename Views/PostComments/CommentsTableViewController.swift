//
//  CommentsTableViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.01.2023.
//

import UIKit
import SDWebImage

class CommentsTableViewController: UIViewController {

    let viewModel = CommentsViewModel()

    let postID: String
    let postCaption: String?
    let timeSincePostedTitle: String
    let postAuthorID: String
    let postAuthorUsername: String
    let postAuthorProfileImage: UIImage
    let isCaptionless: Bool

    var keyboardAccessoryView: CommentAccessoryView = {
        let commentAccessoryView = CommentAccessoryView()
        return commentAccessoryView
    }()

    var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.keyboardDismissMode = .interactive
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.estimatedSectionFooterHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = UITableView.automaticDimension
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.register(CommentTableViewCell.self, forCellReuseIdentifier: CommentTableViewCell.identifier)
        return tableView
    }()

    init(viewModel: PostViewModel) {
        self.postID = viewModel.postID
        self.postCaption = viewModel.unAttributedPostCaption
        self.timeSincePostedTitle = viewModel.timeSincePostedTitle
        self.postAuthorID = viewModel.author.userID
        self.postAuthorUsername = viewModel.author.username
        self.postAuthorProfileImage = viewModel.author.profilePhoto ?? UIImage()
        self.isCaptionless = viewModel.unAttributedPostCaption == nil
        super.init(nibName: nil, bundle: nil)
        tableView.delegate = self
        tableView.dataSource = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Comments"
//        view = tableView
        setupTableViewConstraints()
        keyboardAccessoryView.delegate = self
        configureKeyboardAccessoryView()
        viewModel.getComments(for: self.postID) {
            self.tableView.reloadData()
        }
    }

    override func viewWillLayoutSubviews() {
        keyboardAccessoryView.intrinsicHeight = keyboardAccessoryView.accessoryViewHeight + view.safeAreaInsets.bottom
    }

    func setupTableViewConstraints() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    override var inputAccessoryView: UIView? {
        return keyboardAccessoryView
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }




    // MARK: Methods

    func configureKeyboardAccessoryView() {
        guard let photoURL = AuthenticationManager.shared.getCurrentUserProfilePhotoURL() else {
            return
        }
        keyboardAccessoryView.userProfilePicture.sd_setImage(with: photoURL)
    }

    func scrollToTheLastRow() {
        let lastRow = (tableView.numberOfRows(inSection: isCaptionless ? 0 : 1) - 1)
        guard lastRow >= 1 else {
            return
        }
        self.tableView.scrollToRow(at: IndexPath(row: lastRow, section: isCaptionless ? 0 : 1), at: .bottom, animated: true)
    }

    @objc func keyboardWillAppear() {
        if keyboardAccessoryView.isEditing {
            self.keyboardAccessoryView.intrinsicHeight = keyboardAccessoryView.accessoryViewHeight
            scrollToTheLastRow()
        }
    }

    @objc func keyboardWillDisappear() {
        print("keyboardWillDisappear triggered")
        self.keyboardAccessoryView.intrinsicHeight = keyboardAccessoryView.accessoryViewHeight + view.safeAreaInsets.bottom
    }
}


extension CommentsTableViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: TableView Methods

    func numberOfSections(in tableView: UITableView) -> Int {
        if isCaptionless {
            return 1
        } else {
            return 2
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isCaptionless {
            return viewModel.postComments.count
        } else {
            if section == 0 {
                return 1
            } else {
                return viewModel.postComments.count
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentTableViewCell.identifier,
                                                       for: indexPath) as? CommentTableViewCell
        else {
            fatalError("Could not cast cell")
        }

        if let caption = self.postCaption {
            if indexPath.section == 0 {
                cell.configurePostCaption(caption: caption,
                                          postAuthorUsername: self.postAuthorUsername,
                                          postAuthorProfilePhoto: self.postAuthorProfileImage,
                                          timeSincePostedTitle: self.timeSincePostedTitle)
            } else {
                let comment = viewModel.postComments[indexPath.row]
                cell.configure(with: comment)
            }
        } else {
            let comment = viewModel.postComments[indexPath.row]
            cell.configure(with: comment)
        }
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard isCaptionless == false else {
            return nil
        }

        if section == 0 {
            let separatorView = UIView()
            separatorView.backgroundColor = .secondarySystemBackground
            return separatorView
        } else {
            return UIView()
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return 2
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else {
            return
        }
        if editingStyle == .delete {
            let commentToDelete = viewModel.postComments[indexPath.row]
            tableView.beginUpdates()
            viewModel.deleteComment(commentID: commentToDelete.commentID, postID: self.postID, postAuthorID: self.postAuthorID) {
                self.viewModel.postComments.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.endUpdates()
            }
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.section == 1 else {
            return false
        }

        if postAuthorID == AuthenticationManager.shared.getCurrentUserUID() {
            return true
        } else {
            return false
        }
    }
}

extension CommentsTableViewController: CommentAccessoryViewProtocol {

    func postButtonTapped(commentText: String, completion: @escaping () -> Void) {
        print("post button tapped")
        viewModel.postComment(postID: self.postID, postAuthorID: postAuthorID, comment: commentText) {
            self.tableView.reloadData()
            self.scrollToTheLastRow()
            completion()
        }
    }
}

extension CommentsTableViewController: CommentCellProtocol {
    func openUserProfile(of commentAuthor: ZoogramUser) {
        self.showProfile(of: commentAuthor)
    }
}
