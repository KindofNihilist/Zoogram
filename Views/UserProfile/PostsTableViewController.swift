//
//  PostViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 20.01.2022.
//
import SDWebImage
import UIKit

@MainActor protocol PostsTableViewDelegate: AnyObject {
    func updateCollectionView(with postViewModels: [PostViewModel])
}

class PostsTableViewController: UIViewController {

    var service: any PostsNetworking

    weak var delegate: PostsTableViewDelegate?

    private var postToFocusOn: IndexPath

    private let tableView: PostsTableView

    private lazy var loadingErrorView: LoadingErrorView = {
        let loadingErrorView = LoadingErrorView()
        loadingErrorView.translatesAutoresizingMaskIntoConstraints = false
        return loadingErrorView
    }()

    init(posts: [PostViewModel], service: any PostsNetworking) {
        self.service = service
        self.postToFocusOn = IndexPath(row: 0, section: 0)
        self.tableView = PostsTableView(service: service)
        self.tableView.allowsSelection = false
        self.tableView.separatorStyle = .none
        super.init(nibName: nil, bundle: nil)
        view = tableView
        tableView.setPostsViewModels(postsViewModels: posts)
        tableView.reloadData()
        tableView.postsTableDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.background
        navigationController?.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.setupLoadingIndicatorFooter()
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard isMovingFromParent else {
            return
        }
        updateParentPosts()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tableView.tasks.forEach { task in
            task?.cancel()
        }
    }

    func updateTableViewFrame(to frame: CGRect) {
        self.tableView.frame = frame
    }

    func updatePostsArrayWith(posts: [PostViewModel]) {
        print("updating tableView posts with \(posts.count) posts")
        self.tableView.setPostsViewModels(postsViewModels: posts)
        self.tableView.reloadData()
    }

    func focusTableViewOnPostWith(index: IndexPath) {
        tableView.scrollToRow(at: IndexPath(row: index.row, section: 0), at: .top, animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.tableView.scrollToRow(at: IndexPath(row: index.row, section: 0), at: .top, animated: false)
        }
    }

    private func updateParentPosts() {
        let relevantPosts = tableView.getRetrievedPosts()
        delegate?.updateCollectionView(with: relevantPosts)
    }

    private func showReloadButton(with error: Error) {
        view.addSubview(loadingErrorView)
        loadingErrorView.alpha = 1
        NSLayoutConstraint.activate([
            loadingErrorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingErrorView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            loadingErrorView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -60),
            loadingErrorView.heightAnchor.constraint(equalToConstant: 80)
        ])
        loadingErrorView.setDescriptionLabelText(error.localizedDescription)
        loadingErrorView.delegate = self
    }

    private func hideReloadButton() {
        UIView.animate(withDuration: 0.3) {
            self.loadingErrorView.alpha = 0
        } completion: { _ in
            self.loadingErrorView.removeFromSuperview()
        }
    }
}

extension PostsTableViewController: PostsTableViewProtocol {

    func showLoadingError(_ error: Error) {
        Task {
            let numberOfAllItems = await service.paginationManager.getNumberOfAllItems()
            if numberOfAllItems == 0 {
                showReloadButton(with: error)
            } else {
                showPopUp(issueText: error.localizedDescription)
            }
        }
    }

    func didTapCommentButton(viewModel: PostViewModel) {
        showCommentsFor(viewModel)
    }

    func didSelectUser(user: ZoogramUser) {
        let service = UserProfileService(
            userID: user.userID,
            followService: FollowSystemService.shared,
            userPostsService: UserPostsService.shared,
            userService: UserDataService(),
            likeSystemService: LikeSystemService.shared,
            bookmarksService: BookmarksSystemService.shared)
        let userProfileVC = UserProfileViewController(service: service, user: user, isTabBarItem: false)
        userProfileVC.title = user.username
        self.navigationController?.pushViewController(userProfileVC, animated: true)
    }

    func didTapMenuButton(postModel: PostViewModel, indexPath: IndexPath) {
        showMenuForPost(postViewModel: postModel) {
            self.tableView.deletePost(at: indexPath) { result in
                switch result {
                case .success:
                    sendNotificationToUpdateUserFeed()
                case .failure(let error):
                    self.showPopUp(issueText: error.localizedDescription)
                }

            }
        }
    }
}

extension PostsTableViewController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController != self {
            navigationController.popViewController(animated: true)
        }
    }
}

extension PostsTableViewController: LoadingErrorViewDelegate {
    func didTapReloadButton() {
        hideReloadButton()
        tableView.refreshControl?.beginRefreshingManually()
    }
}
