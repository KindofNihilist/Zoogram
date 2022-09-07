//
//  PostViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 20.01.2022.
//
import SDWebImage
import UIKit

enum PostSubviewType {
    case header(provider: User)
    case postContent(provider: UserPost)
    case actions(provider: String)
    case comment(comment: PostComment)
    case footer(provied: UserPost)
}

struct PostViewModel {
    let subviews: [PostSubviewType]
}

class PostViewController: UIViewController {
    
    private let postModel: UserPost?
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(PostContentTableViewCell.self, forCellReuseIdentifier: PostContentTableViewCell.identifier)
        tableView.register(PostHeaderTableViewCell.self, forCellReuseIdentifier: PostHeaderTableViewCell.identifier)
        tableView.register(PostActionsTableViewCell.self, forCellReuseIdentifier: PostActionsTableViewCell.identifier)
        tableView.register(PostCommentsTableViewCell.self, forCellReuseIdentifier: PostCommentsTableViewCell.identifier)
        tableView.register(PostFooterTableViewCell.self, forCellReuseIdentifier: PostFooterTableViewCell.identifier)
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        return tableView
    }()
    
    private var postViewModels = [PostViewModel]()
    
    init(model: UserPost?) {
        self.postModel = model
        super.init(nibName: nil, bundle: nil)
        self.configureModels()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        view.backgroundColor = .systemBackground
    }
    
    private func configureModels() {
        guard let userPostModel = self.postModel else {
            return
        }
        var post = [PostSubviewType]()
        post.append(PostSubviewType.header(provider: userPostModel.owner))
        post.append(PostSubviewType.postContent(provider: userPostModel))
        post.append(PostSubviewType.actions(provider: ""))
        post.append(PostSubviewType.footer(provied: userPostModel))
        for i in 0 ..< 10 {
            post.append(PostSubviewType.comment(comment: PostComment(
                identifier: "id_\(i)",
                commentAuthorUsername: "bigTrumpet",
                text: "Great post lmao",
                createdDate: Date(),
                likes: []
            )
                                               )
                        
            )
        }
        postViewModels.append(PostViewModel(subviews: post))
    }
}




extension PostViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return postViewModels.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postViewModels[section].subviews.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = postViewModels[indexPath.section]
        switch model.subviews[indexPath.row] {
        case .header(let provider):
            let cell = tableView.dequeueReusableCell(withIdentifier: PostHeaderTableViewCell.identifier, for: indexPath) as! PostHeaderTableViewCell
            cell.configure(with: provider)
            return cell
        case .postContent(let post):
            let cell = tableView.dequeueReusableCell(withIdentifier: PostContentTableViewCell.identifier, for: indexPath) as! PostContentTableViewCell
            SDWebImageManager.shared.loadImage(with: post.thumbnailImage, options: [.highPriority], progress: nil) { (image, data, error, cacheType, finished, url) in
                cell.configure(with: image)
            }
            return cell
        case .actions(let actions):
            let cell = tableView.dequeueReusableCell(withIdentifier: PostActionsTableViewCell.identifier, for: indexPath) as! PostActionsTableViewCell
            return cell
        case .footer(let post):
            let cell = tableView.dequeueReusableCell(withIdentifier: PostFooterTableViewCell.identifier, for: indexPath) as! PostFooterTableViewCell
            cell.configure(for: post)
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
        case .actions(_): return 45
        case .footer(_): return UITableView.automaticDimension
        case .comment(_): return 50
        }
    }
    
}
