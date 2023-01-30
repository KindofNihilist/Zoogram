//
//  CommentsTableViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.01.2023.
//

import UIKit

class CommentsTableViewController: UITableViewController {
    
    var keyboardAccessoryView: CommentAccessoryView = {
        let commentAccessoryView = CommentAccessoryView()
        return commentAccessoryView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Comments"
        keyboardAccessoryView.delegate = self
        keyboardAccessoryView.topAnchor.constraint(equalTo: tableView.bottomAnchor).isActive = true
        keyboardAccessoryView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.backgroundColor = .systemBackground
        tableView.keyboardDismissMode = .interactive
    }
    
    override var inputAccessoryView: UIView? {
        return keyboardAccessoryView
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        tabBarController?.tabBar.isHidden = true
//        tabBarController?.tabBar.backgroundColor = .systemOrange
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        tabBarController?.tabBar.isHidden = false
    }
    
    
    
//    override var inputView: UIView? {
//        let commentAccessoryView = CommentAccessoryView()
//        commentAccessoryView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 60)
//        commentAccessoryView.setViewCornerRadius(forHeight: commentAccessoryView.frame.height)
//        return commentAccessoryView
//    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
}

extension CommentsTableViewController: CommentAccessoryViewProtocol {
    func postButtonTapped(commentText: String) {
        print(commentText)
        print("post button tapped")
    }
}
