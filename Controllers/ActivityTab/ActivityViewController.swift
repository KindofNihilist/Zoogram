//
//  ActivityViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//

import UIKit

enum UserActivityType {
    case liked(post: UserPost)
    case followed(state: FollowState)
    case commented
}

struct UserActivity {
    let type: UserActivityType
    let text: String
    let user: ZoogramUser
}

class ActivityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(PostLikedTableViewCell.self, forCellReuseIdentifier: PostLikedTableViewCell.identifier)
        tableView.register(FollowEventTableViewCell.self, forCellReuseIdentifier: FollowEventTableViewCell.identifier)
        return tableView
    }()
    
    private lazy var noNotificationsView = NoNotificationsView()
    
    private var models = [UserActivity]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchActivity()
    }
    
    override func viewDidLoad() {
        view.backgroundColor = .systemBackground
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        setupNavigationBar()
        checkNotificationsAvailability()
    }
    
    private func setupNavigationBar() {
        guard let navBar = navigationController?.navigationBar else {
            return
        }
        let label: UILabel = {
            let label = UILabel()
            label.text = "Activity"
            label.font = UIFont.boldSystemFont(ofSize: 20)
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        navBar.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 15),
            label.widthAnchor.constraint(equalToConstant: 100),
            label.heightAnchor.constraint(equalTo: navBar.heightAnchor, constant: -10),
            label.centerXAnchor.constraint(equalTo: navBar.centerXAnchor)
        ])
    }
    
    
    
    private func checkNotificationsAvailability() {
        if models.isEmpty {
            view = noNotificationsView
        } else {
            view = tableView
        }
    }
    
    private func fetchActivity() {
//        let userMock = User(profilePhotoURL: "https://cdn.ballotpedia.org/images/0/0b/Biden_Square.png", emailAdress: "", username: "username", name: "Joe", bio: "", birthday: "12/12/1986", gender: "male", counts: UserCount(followers: 1, following: 1, posts: 1), joinDate: Date().timeIntervalSince1970)
//
//        for i in 0...30 {
//            let post = UserPost(identifier: "", postType: .photo, thumbnailImage: URL(string: "https://wallpaperaccess.com/full/235592.jpg")!, postURL: URL(string: "https://www.google.com/")! , caption: "Asking to be booped", likeCount: [], comments: [], postedDate: Date(), taggedUsers: [], owner: userMock)
//
//            let model = UserActivity(type: (i % 2 == 0) ? .liked(post: post ) : .followed(state: .notFollowing), text: "Hi there booois", user: userMock )
//            models.append(model)
//        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.row]
        switch model.type {
        case .liked(_):
            let cell = tableView.dequeueReusableCell(withIdentifier: PostLikedTableViewCell.identifier, for: indexPath) as! PostLikedTableViewCell
            cell.selectionStyle = .none
            cell.configure(with: model)
            cell.delegate = self
            return cell
        case .followed:
            let cell = tableView.dequeueReusableCell(withIdentifier: FollowEventTableViewCell.identifier, for: indexPath) as! FollowEventTableViewCell
            cell.selectionStyle = .none
            cell.configure(with: model)
            cell.delegate = self
            return cell
        case .commented:
            let cell = tableView.dequeueReusableCell(withIdentifier: PostLikedTableViewCell.identifier, for: indexPath) as! PostLikedTableViewCell
            cell.selectionStyle = .none
            cell.configure(with: model)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = models[indexPath.row]
        switch model.type {
        case .liked(let post):
            let vc = PostViewController(model: post)
            present(vc, animated: true)
        case .followed(_):
            break
        case .commented:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }
}

extension ActivityViewController: PostLikedTableViewCellDelegate {
    func didTapRelatedPost(model: UserActivity) {
        switch model.type {
        case .liked(let post):
            let vc = UINavigationController(rootViewController: PostViewController(model: post))
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated:  true)
        case .followed(_):
            break
        case .commented:
            break
        }
    }
    
    
}


extension ActivityViewController: FollowEventTableViewCellDelegate {
    func didTapFollowUnfollowButton(model: UserActivity) {
        
    }
    
    
}
