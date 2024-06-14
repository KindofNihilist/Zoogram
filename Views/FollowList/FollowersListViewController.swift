//
//  ListViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 21.01.2022.
//

import UIKit

enum FollowListType {
    case following, followers
}

class FollowersListViewController: ViewControllerWithLoadingIndicator {

    private let viewModel: FollowListViewModel
    private var tasks = [Task<Void, Never>?]()
    internal var factory: FollowListFactory!
    private var dataSource: DefaultTableViewDataSource!

    internal let tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = Colors.background
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private lazy var messageImageView: UIImageView = {
        let imageview = UIImageView()
        imageview.image = UIImage(systemName: "person.crop.circle.badge.plus",
                                  withConfiguration: UIImage.SymbolConfiguration(pointSize: 25))
        imageview.contentMode = .scaleAspectFit
        imageview.tintColor = Colors.label
        imageview.translatesAutoresizingMaskIntoConstraints = false
        return imageview
    }()

    internal lazy var messageTitle: UILabel = {
        let label = UILabel()
        label.font = CustomFonts.boldFont(ofSize: 20)
        label.sizeToFit()
        label.textColor = Colors.label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    internal lazy var message: UILabel = {
        let label = UILabel()
        label.font = CustomFonts.regularFont(ofSize: 15)
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(service: FollowListServiceProtocol, isUserProfile: Bool) {
        self.viewModel = FollowListViewModel(service: service, isUserProfile: isUserProfile)
        super.init()
        view.backgroundColor = Colors.background
        mainView = tableView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard isMovingToParent else {
            return
        }

        self.reloadAction = {
            self.getData()
        }

        self.getData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
//        tasks.forEach { task in
//            task?.cancel()
//        }
    }

    private func getData() {
        let task = Task {
            do {
                let userList = try await viewModel.getUserList()
                if userList.isEmpty {
                    self.showNoUsersMessage()
                } else {
                    self.setupFactory()
                }
                self.showMainView()
            } catch {
                self.showLoadingErrorNotification(text: error.localizedDescription)
            }
        }
        tasks.append(task)
    }

    internal func setFactory() {
        if viewModel.isUserProfile {
            self.factory = FollowersListFactory(tableView: self.tableView, delegate: self)
        } else {
            self.factory = FollowingListFactory(tableView: self.tableView, delegate: self)
        }
    }

    private func setActionOnSelection() {
        self.factory.selectionAction = { indexPath in
            let user = self.viewModel.userList[indexPath.row]
            self.showProfile(of: user)
        }
    }

    private func setupFactory() {
        setFactory()
        setActionOnSelection()
        factory.buildSections(for: self.viewModel.userList) { sections in
            self.dataSource = DefaultTableViewDataSource(sections: sections)
            self.tableView.delegate = self.dataSource
            self.tableView.dataSource = self.dataSource
            self.tableView.reloadData()
        }
    }

    internal func configureMessageView(isUserProfile: Bool) {
        let localizedTitle = String(localized: "Followers")
        var localizedMessage: String

        if isUserProfile {
            localizedMessage = String(localized: "You'll see all of the people who follow you here.")
        } else {
            localizedMessage = String(localized: "Seems like nobody is following this user")
        }
        messageTitle.text = localizedTitle
        message.text = localizedMessage
    }

    private func showNoUsersMessage() {
        self.view.addSubviews(messageTitle, messageImageView, message)
        setupMessageConstraints()
        configureMessageView(isUserProfile: viewModel.isUserProfile)
    }

    private func setupMessageConstraints() {
         NSLayoutConstraint.activate([
             messageImageView.bottomAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
             messageImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
             messageImageView.heightAnchor.constraint(equalToConstant: 80),
             messageImageView.widthAnchor.constraint(equalToConstant: 80),

             messageTitle.topAnchor.constraint(equalTo: messageImageView.bottomAnchor, constant: 5),
             messageTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),

             message.topAnchor.constraint(equalTo: messageTitle.bottomAnchor, constant: 10),
             message.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
             message.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
             message.centerXAnchor.constraint(equalTo: view.centerXAnchor)

         ])
     }

    private func setupTableView() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    @objc func popBack() {
        self.navigationController?.popViewController(animated: true)
    }
}

extension FollowersListViewController: FollowListCellDelegate {
    func removeButtonTapped(userID: String, removeCompletion: @escaping (FollowStatus) -> Void) {
        let task = Task {
            do {
                try await viewModel.removeUserFollowingMe(uid: userID)
                removeCompletion(.notFollowing)
            } catch {
                self.showPopUp(issueText: error.localizedDescription)
            }
        }
        tasks.append(task)
    }

    func undoButtonTapped(userID: String, undoCompletion: @escaping (FollowStatus) -> Void) {
        let task = Task {
            do {
                try await viewModel.undoUserRemoval(uid: userID)
                undoCompletion(.following)
            } catch {
                self.showPopUp(issueText: error.localizedDescription)
            }
        }
        tasks.append(task)
    }

    func followButtonTapped(userID: String, followCompletion: @escaping (FollowStatus) -> Void) {
        let task = Task {
            do {
                let newFollowStatus = try await viewModel.followUser(uid: userID)
                followCompletion(newFollowStatus)
            } catch {
                self.showPopUp(issueText: error.localizedDescription)
            }
        }
        tasks.append(task)
    }

    func unfollowButtonTapped(userID: String, unfollowCompletion: @escaping (FollowStatus) -> Void) {
        let task = Task {
            do {
                let newFollowStatus = try await viewModel.unfollowUser(uid: userID)
                unfollowCompletion(newFollowStatus)
            } catch {
                self.showPopUp(issueText: error.localizedDescription)
            }
        }
        tasks.append(task)
    }
}
