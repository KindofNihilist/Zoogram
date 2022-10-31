//
//  HomeViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//
import SDWebImage
import FirebaseAuth
import UIKit

class HomeViewController: UIViewController {
    
    private var postModels = [UserPost]()
    
    private var postViewModels = [PostModel]()
    
    private let feedTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(PostContentTableViewCell.self, forCellReuseIdentifier: PostContentTableViewCell.identifier)
        tableView.register(PostHeaderTableViewCell.self, forCellReuseIdentifier: PostHeaderTableViewCell.identifier)
        tableView.register(PostActionsTableViewCell.self, forCellReuseIdentifier: PostActionsTableViewCell.identifier)
        tableView.register(PostCommentsTableViewCell.self, forCellReuseIdentifier: PostCommentsTableViewCell.identifier)
        tableView.register(PostFooterTableViewCell.self, forCellReuseIdentifier: PostFooterTableViewCell.identifier)
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureModels()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        feedTableView.delegate = self
        feedTableView.dataSource = self
        view.addSubview(feedTableView)
        feedTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        feedTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        feedTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        feedTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        setupNavigationBar()
    }
        
    private func configureModels() {
        for post in postModels {
            var postView = [PostSubviewType]()
            postView.append(PostSubviewType.header(profilePictureURL: "", username: "username"))
            postView.append(PostSubviewType.postContent(provider: post))
            postView.append(PostSubviewType.actions(provider: ""))
            postView.append(PostSubviewType.footer(provider: post, username: "username"))
            postViewModels.append(PostModel(subviews: postView))
        }
        print(postModels.count)
    }
    
    private func setupNavigationBar() {
        let label: UILabel = {
            let label = UILabel()
            label.text = "Zoogram"
            label.font = UIFont(name: "Noteworthy-Bold", size: 25)
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: label)
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return postViewModels.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postViewModels[section].subviews.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = postViewModels[indexPath.section]
        switch model.subviews[indexPath.row] {
            
        case .header(let profilePictureURL, let username):
            let cell = tableView.dequeueReusableCell(withIdentifier: PostHeaderTableViewCell.identifier, for: indexPath) as! PostHeaderTableViewCell
            cell.configureWith(profilePictureURL: profilePictureURL, username: username)
            return cell
            
        case .postContent(let post):
            let cell = tableView.dequeueReusableCell(withIdentifier: PostContentTableViewCell.identifier, for: indexPath) as! PostContentTableViewCell
//            SDWebImageManager.shared.loadImage(with: URL(string: post.photoURL), options: [.highPriority], progress: nil) { (image, data, error, cacheType, finished, url) in
//                cell.configure(with: image)
//            }
            return cell
            
        case .actions(let actions):
            let cell = tableView.dequeueReusableCell(withIdentifier: PostActionsTableViewCell.identifier, for: indexPath) as! PostActionsTableViewCell
            return cell
            
        case .footer(let post, let username):
            let cell = tableView.dequeueReusableCell(withIdentifier: PostFooterTableViewCell.identifier, for: indexPath) as! PostFooterTableViewCell
            cell.configure(for: post, username: username)
            return cell
            
        case .comment(let comment):
            let cell = tableView.dequeueReusableCell(withIdentifier: PostCommentsTableViewCell.identifier, for: indexPath) as! PostCommentsTableViewCell
            cell.configure(with: comment)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let model = postViewModels[indexPath.section]
        switch model.subviews[indexPath.row] {
        case .header(_): return 50
        case .postContent(_): return UITableView.automaticDimension
        case .actions(_): return 50
        case .footer(_): return UITableView.automaticDimension
        case .comment(_): return 50
        }
    }
    
}
