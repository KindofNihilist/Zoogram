//
//  ActivityViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//

import UIKit

protocol ActivityViewUnseenEventsProtocol {
    func userHasSeenAllActivityEvents()
}

protocol ActivityViewCellActionsDelegate: AnyObject {
    func didSelectUser(user: ZoogramUser)
    func didSelectRelatedPost(post: UserPost, postPhoto: UIImage, shouldFocusOnComment: Bool, commentID: String)
}

class ActivityViewController: UIViewController {
    
    var delegate: ActivityViewUnseenEventsProtocol?
    
    private var activityEvents = [ActivityEvent]()
    
    private let viewModel = ActivityViewModel()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(PostLikedEventTableViewCell.self, forCellReuseIdentifier: PostLikedEventTableViewCell.identifier)
        tableView.register(FollowEventTableViewCell.self, forCellReuseIdentifier: FollowEventTableViewCell.identifier)
        tableView.register(PostCommentedEventTableViewCell.self, forCellReuseIdentifier: PostCommentedEventTableViewCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.translatesAutoresizingMaskIntoConstraints = false
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
        label.text = "Activity"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    //MARK: Lifecycle
    override func viewDidLoad() {
        view.backgroundColor = .systemBackground
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        setupViewsConstraints()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: activityNavBarlabel)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkNotificationsAvailability()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard activityEvents.isEmpty == false else {
            return
        }
        viewModel.getAdditionalDataForEvents(events: self.activityEvents) {
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                self.checkIfCellisFullyVisible()
                self.markSeenEvents(delay: 0.5)
            }
            self.tableView.reloadData()
            CATransaction.commit()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ActivityService.shared.updateActivityEventsSeenStatus(events: viewModel.seenEvents) {
            self.viewModel.seenEvents = Set<ActivityEvent>()
        }
    }
    
    
    //MARK: Views setup
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
    
    //MARK: Methods
    func updateEvents(_ events: [ActivityEvent]) {
        self.activityEvents = events
    }
    
    private func checkNotificationsAvailability() {
        if activityEvents.isEmpty {
            tableView.isHidden = true
            tableView.isUserInteractionEnabled = false
            noNotificationsView.isHidden = false
        } else {
            print("table view is hidden == false")
            noNotificationsView.isHidden = true
            tableView.isHidden = false
            tableView.isUserInteractionEnabled = true
        }
    }
    
    private func checkIfCellisFullyVisible(completion: () -> Void = {}) {
        let visibleCells = tableView.indexPathsForVisibleRows
        
        visibleCells?.forEach { indexPath in
            guard viewModel.events[indexPath.row].seen != true else {
                return
            }
            
            let cellFrame = tableView.rectForRow(at: indexPath)
            
            if tableView.bounds.contains(cellFrame) {
                self.viewModel.events[indexPath.row].seen = true
                let seenEvent = viewModel.events[indexPath.row]
                self.viewModel.seenEvents.insert(seenEvent)
            }
        }
        completion()
    }
    
    private func markSeenEvents(delay: CFTimeInterval = 0) {
        let visibleCells = tableView.indexPathsForVisibleRows
    
        UIView.animate(withDuration: 0.4, delay: delay, options: .allowAnimatedContent) {
            visibleCells?.forEach({ indexPath in
                self.tableView.cellForRow(at: indexPath)?.contentView.backgroundColor = .systemBackground
            })
        } completion: { _ in
            if self.viewModel.events.filter({$0.seen == false}).count == 0 {
                self.delegate?.userHasSeenAllActivityEvents()
            }
        }
    }
}

//MARK: TableView Delegate
extension ActivityViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = viewModel.events[indexPath.row]
        
        switch event.eventType {
            
        case .postLiked:
            guard event.user != nil && event.post != nil else {
                return UITableViewCell()
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: PostLikedEventTableViewCell.identifier, for: indexPath) as! PostLikedEventTableViewCell
            cell.selectionStyle = .none
            cell.configure(with: event)
            cell.delegate = self
            return cell
            
        case .followed:
            guard event.user != nil else {
                return UITableViewCell()
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: FollowEventTableViewCell.identifier, for: indexPath) as! FollowEventTableViewCell
            cell.selectionStyle = .none
            cell.configure(with: event)
            cell.delegate = self
            return cell
            
        case .postCommented:
            guard event.text != nil && event.user != nil && event.post != nil else {
                return UITableViewCell()
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: PostCommentedEventTableViewCell.identifier, for: indexPath) as! PostCommentedEventTableViewCell
            cell.selectionStyle = .none
            cell.configure(with: event)
            cell.delegate = self
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = viewModel.events[indexPath.row]
        
        switch model.eventType {
            
        case .postLiked:
            return
//            let vc = PostViewController(posts: [post])
//            present(vc, animated: true)
            
        case .followed:
            return
            
        case .postCommented:
            return
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        checkIfCellisFullyVisible()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        markSeenEvents()
    }
    
}

//MARK: Cell actions Delegate
extension ActivityViewController: ActivityViewCellActionsDelegate {
    func didSelectUser(user: ZoogramUser) {
        let userProfileViewController = UserProfileViewController(isTabBarItem: false)
        userProfileViewController.title = user.username
        userProfileViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(userProfileViewController, animated: true)
//        self.activityNavBarlabel.isHidden = true
    }
    
    func didSelectRelatedPost(post: UserPost, postPhoto: UIImage, shouldFocusOnComment: Bool = false, commentID: String = "") {
//        let vc = PostViewController(posts: [post])
//        vc.hidesBottomBarWhenPushed = true
//        self.navigationController?.pushViewController(vc, animated: true)
//        self.activityNavBarlabel.isHidden = true
    }
        
}


extension ActivityViewController: FollowEventTableViewCellDelegate {
    func followUserTapped(user: ZoogramUser, followCompletion: @escaping (FollowStatus) -> Void) {
        FollowService.shared.followUser(uid: user.userID) { followStatus in
            followCompletion(followStatus)
        }
    }
    
    func unfollowUserTapped(user: ZoogramUser, unfollowCompletion: @escaping (FollowStatus) -> Void) {
        FollowService.shared.unfollowUser(uid: user.userID) { followSatus in
            ActivityService.shared.removeFollowEventForUser(userID: user.userID)
            unfollowCompletion(followSatus)
        }
    }
}
