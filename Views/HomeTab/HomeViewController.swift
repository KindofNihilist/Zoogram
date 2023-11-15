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

    let service: HomeFeedService

    let tableView: PostsTableView

    private var notificationView: UIView?
    private var notificationViewTopAnchor: NSLayoutConstraint!

    init(service: HomeFeedService!) {
        self.service = service
        self.tableView = {
            let tableView = PostsTableView(service: service)
            tableView.allowsSelection = false
            tableView.separatorStyle = .none
            return tableView
        }()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view = tableView
        setNavigationBarTitle()
        tableView.postsTableDelegate = self
        tableView.refreshUserFeed()
        view.backgroundColor = .systemBackground
    }

    func setNavigationBarTitle() {
        let navigationBarTitleLabel = UILabel()
        navigationBarTitleLabel.text = "Zoogram"
        navigationBarTitleLabel.font = CustomFonts.logoFont(ofSize: 28)
        navigationBarTitleLabel.sizeToFit()

//        for family in UIFont.familyNames.sorted() {
//            let names = UIFont.fontNames(forFamilyName: family)
//            print("Family: \(family) Font names: \(names)")
//        }

        let titleView = UIBarButtonItem(customView: navigationBarTitleLabel)
        navigationItem.titleView = navigationBarTitleLabel
    }

    func showMakingNewPostNotificationViewFor(username: String, with postImage: UIImage?) {
        notificationView = MakingNewPostNotificationView(photo: postImage, username: username)
        notificationView?.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(notificationView!)
        notificationViewTopAnchor = notificationView!.topAnchor.constraint(equalTo: view.topAnchor)
        tableView.insertBlankCell()
        tableView.isUserInteractionEnabled = false
        NSLayoutConstraint.activate([
            notificationViewTopAnchor,
            notificationView!.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            notificationView!.widthAnchor.constraint(equalTo: view.widthAnchor),
            notificationView!.heightAnchor.constraint(equalToConstant: PostTableViewCell.headerHeight)
        ])
    }

    func updateProgressBar(progress: Progress?) {
        guard let notificationView = self.notificationView as? MakingNewPostNotificationView else {
            return
        }
        notificationView.setProgressToProgressBar(progress: progress)
    }

    func animateInsertionOfCreatedPost(post: UserPost) {
        guard let notificationView = self.notificationView as? MakingNewPostNotificationView else {
            return
        }
        let postViewModel = PostViewModel(post: post)
        tableView.replaceBlankCellWithNewlyCreatedPost(postViewModel: postViewModel)
        UIView.animate(withDuration: 0.7) {
            notificationView.expand()
        } completion: { _ in
            self.tableView.makeNewlyCreatedPostVisible(at: IndexPath(row: 0, section: 0)) {
                self.notificationView?.removeFromSuperview()
                self.tableView.isUserInteractionEnabled = true
            }
        }

    }

    func handlePostCreationError(error: Error) {
        self.show(error: error)
        self.tableView.isUserInteractionEnabled = true
    }

    func focusTableViewOnPostWith(index: IndexPath) {
        tableView.scrollToRow(at: index, at: .top, animated: false)
    }

    func setTableViewVisibleContentToTop(animated: Bool) {
        tableView.setContentOffset(CGPoint.zero, animated: animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.tableView.setContentOffset(CGPoint.zero, animated: animated)
        }
    }
}

extension HomeViewController: PostsTableViewProtocol {

    func didTapCommentButton(viewModel: PostViewModel) {
        showCommentsFor(viewModel)
    }

    func didSelectUser(user: ZoogramUser) {
        showProfile(of: user)
    }

    func didTapMenuButton(postModel: PostViewModel, indexPath: IndexPath) {
        showMenuForPost(postViewModel: postModel, onDelete: {
            self.tableView.deletePost(at: indexPath) {
                sendNotificationToUpdateUserProfile()
            }
        })
    }
}
