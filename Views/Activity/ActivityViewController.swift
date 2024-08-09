//
//  ActivityViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//

import UIKit

@MainActor
protocol ActivityViewNotificationProtocol: AnyObject {
    func displayUnseenEventsBadge()
    func removeUnseenEventsBadge()
}

@MainActor
protocol ActivityViewCellActionsDelegate: AnyObject, UITextViewDelegate {
    func didSelectUser(user: ZoogramUser)
}

class ActivityViewController: UIViewController {

    weak var delegate: ActivityViewNotificationProtocol?

    private let viewModel: ActivityViewModel

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(PostLikedEventTableViewCell.self, forCellReuseIdentifier: PostLikedEventTableViewCell.identifier)
        tableView.register(FollowEventTableViewCell.self, forCellReuseIdentifier: FollowEventTableViewCell.identifier)
        tableView.register(PostCommentedEventTableViewCell.self, forCellReuseIdentifier: PostCommentedEventTableViewCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = Colors.background
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()

    private lazy var noNotificationsView: NoNotificationsView = {
        let noNotificationsView = NoNotificationsView()
        noNotificationsView.translatesAutoresizingMaskIntoConstraints = false
        noNotificationsView.isHidden = true
        noNotificationsView.isUserInteractionEnabled = false
        return noNotificationsView
    }()

    let activityNavBarlabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "Activity")
        label.font = CustomFonts.boldFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(service: ActivityServiceProtocol) {
        self.viewModel = ActivityViewModel(service: service)
        super.init(nibName: nil, bundle: nil)

        viewModel.hasUnseenEvents.bind { hasUnseenEvents in
            if hasUnseenEvents {
                self.delegate?.displayUnseenEventsBadge()
            } else {
                self.delegate?.removeUnseenEventsBadge()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Lifecycle
    override func viewDidLoad() {
        view.backgroundColor = Colors.background
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: activityNavBarlabel)
        tableView.delegate = self
        tableView.dataSource = self
        setupViewsConstraints()
        setupPullToRefresh()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkNotificationsAvailability()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
        showRecentNotifications(animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Task {
            do {
                try await viewModel.updateActivityEventsSeenStatus()
            } catch {
                showPopUp(issueText: error.localizedDescription)
            }
        }
    }

    // MARK: Views setup
    private func setupViewsConstraints() {
        view.addSubviews(tableView, noNotificationsView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            noNotificationsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            noNotificationsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noNotificationsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noNotificationsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: Methods
    private func setupPullToRefresh() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshTableView), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    private func showRecentNotifications(animated: Bool) {
        guard viewModel.hasZeroEvents != true else {
            return
        }
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .none, animated: animated)
            self.markFullyVisibleEventsAsSeen()
            self.animateSeenEventsStatusChange(delay: 0.5)
        }
        self.tableView.reloadData()
        CATransaction.commit()
    }

    private func checkNotificationsAvailability() {
        if viewModel.hasZeroEvents {
            tableView.isHidden = true
            tableView.isUserInteractionEnabled = false
            noNotificationsView.isHidden = false
        } else {
            noNotificationsView.isHidden = true
            tableView.isHidden = false
            tableView.isUserInteractionEnabled = true
        }
    }

    private func markFullyVisibleEventsAsSeen(completion: () -> Void = {}) {
        let visibleCells = tableView.indexPathsForVisibleRows

        visibleCells?.forEach { indexPath in
            guard viewModel.eventSeenStatus(at: indexPath) != true else {
                return
            }

            let cellFrame = tableView.rectForRow(at: indexPath)

            if tableView.bounds.contains(cellFrame) {
                viewModel.markEventAsSeen(at: indexPath)
            }
        }
        completion()
    }

    private func animateSeenEventsStatusChange(delay: CFTimeInterval = 0) {
        let visibleCells = tableView.indexPathsForVisibleRows

        UIView.animate(withDuration: 0.4, delay: delay, options: .allowAnimatedContent) {
            visibleCells?.forEach({ indexPath in
                self.tableView.cellForRow(at: indexPath)?.contentView.backgroundColor = Colors.background
            })
        } completion: { _ in
            self.viewModel.checkIfHasUnseenEvents()
        }
    }

    private func presentPostWithComments(post: UserPost?, commentIDToFocusOn: String?) {
        guard let post = post else { return }
        let service = CommentsService(
            postID: post.postID,
            postAuthorID: post.author.userID,
            userDataService: UserDataService(),
            postsService: UserPostsService.shared,
            commentsService: CommentSystemService.shared,
            likesService: LikeSystemService.shared,
            bookmarksService: BookmarksSystemService.shared)

        let postWithCommentsVC = CommentsViewController(
            post: post,
            commentIDToFocusOn: commentIDToFocusOn,
            shouldShowRelatedPost: true,
            service: service)
        postWithCommentsVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(postWithCommentsVC, animated: true)
    }

    func observeActivityEvents() {
        viewModel.observeActivityEvents()
    }

    @objc private func refreshTableView() {
        showRecentNotifications(animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.tableView.refreshControl?.endRefreshing()
        }
    }
}

// MARK: TableView Delegate
extension ActivityViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.eventsCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = viewModel.getEvent(for: indexPath)

        switch event.eventType {

        case .postLiked:
            let cell: PostLikedEventTableViewCell = tableView.dequeue(withIdentifier: PostLikedEventTableViewCell.identifier, for: indexPath)
            cell.configure(with: event)
            cell.delegate = self
            return cell

        case .followed:
            let cell: FollowEventTableViewCell = tableView.dequeue(withIdentifier: FollowEventTableViewCell.identifier, for: indexPath)
            cell.configure(with: event)
            cell.delegate = self
            return cell

        case .postCommented:
            let cell: PostCommentedEventTableViewCell = tableView.dequeue(withIdentifier: PostCommentedEventTableViewCell.identifier, for: indexPath)
            cell.configure(with: event)
            cell.delegate = self
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let event = viewModel.getEvent(for: indexPath)

        switch event.eventType {

        case .postLiked:
            presentPostWithComments(post: event.post, commentIDToFocusOn: event.commentID)
        case .followed:
            guard let user = event.user else {
                return
            }
            showProfile(of: user)
        case .postCommented:
            presentPostWithComments(post: event.post, commentIDToFocusOn: event.commentID)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        markFullyVisibleEventsAsSeen()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        animateSeenEventsStatusChange()
    }

}

// MARK: Cell actions Delegate
extension ActivityViewController: ActivityViewCellActionsDelegate {
    func didSelectUser(user: ZoogramUser) {
        showProfile(of: user)
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let userID = URL.absoluteString
        let user = ZoogramUser(userID)
        showProfile(of: user)
        return true
    }
}

extension ActivityViewController: FollowEventTableViewCellDelegate {
    func followUserTapped(user: ZoogramUser) {
        Task {
            do {
                try await FollowSystemService.shared.followUser(uid: user.userID)
            } catch {
                self.showPopUp(issueText: error.localizedDescription)
            }
        }
    }

    func unfollowUserTapped(user: ZoogramUser) {
        Task {
            do {
                try await FollowSystemService.shared.unfollowUser(uid: user.userID)
            } catch {
                self.showPopUp(issueText: error.localizedDescription)
            }
        }
    }
}
