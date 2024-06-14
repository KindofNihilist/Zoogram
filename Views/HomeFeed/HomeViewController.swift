//
//  HomeViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//
import SDWebImage
import FirebaseAuth
import UIKit

enum ScrollDirection {
    case upwards
    case downwards
    case none
}

class HomeViewController: UIViewController {

    let service: any HomeFeedServiceProtocol
    private var task: Task<Void, Error>?

    let tableView: PostsTableView

    private var notificationView: UIView?
    private var notificationViewTopAnchor: NSLayoutConstraint!

    private var latestScrollDirection: ScrollDirection = .none
    private var headerHeight: CGFloat = 45
    private var headerLogoTopConstraint: NSLayoutConstraint!

    private lazy var loadingErrorView: LoadingErrorView = {
        let loadingErrorView = LoadingErrorView()
        loadingErrorView.translatesAutoresizingMaskIntoConstraints = false
        return loadingErrorView
    }()

    private var headerLogoView: UIView = {
        let headerLogoView = UIView()
        headerLogoView.translatesAutoresizingMaskIntoConstraints = false
        let navigationBarTitleLabel = UILabel()
        navigationBarTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        navigationBarTitleLabel.text = "Zoogram"
        navigationBarTitleLabel.font = CustomFonts.logoFont(ofSize: 25)
        navigationBarTitleLabel.sizeToFit()
        headerLogoView.addSubview(navigationBarTitleLabel)
        navigationBarTitleLabel.centerXAnchor.constraint(equalTo: headerLogoView.centerXAnchor).isActive = true
        navigationBarTitleLabel.centerYAnchor.constraint(equalTo: headerLogoView.centerYAnchor).isActive = true
        return headerLogoView
    }()

    init(service: any HomeFeedServiceProtocol) {
        self.service = service
        self.tableView = {
            let tableView = PostsTableView(service: service)
            tableView.translatesAutoresizingMaskIntoConstraints = false
            tableView.allowsSelection = false
            tableView.separatorStyle = .none
            return tableView
        }()
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = Colors.background
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubviews(headerLogoView, tableView)
        setupConstraints()
        setupTableViewDidScrollAction()
        setupTableViewDidEndScrollAction()
        tableView.postsTableDelegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.isBeingPresented || self.isMovingToParent {
            tableView.refreshControl?.beginRefreshingManually()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tableView.tasks.forEach { task in
            task?.cancel()
        }
        task?.cancel()
    }

    private func setupConstraints() {
        headerLogoTopConstraint = headerLogoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        NSLayoutConstraint.activate([
            headerLogoTopConstraint,
            headerLogoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerLogoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerLogoView.heightAnchor.constraint(equalToConstant: headerHeight),

            tableView.topAnchor.constraint(equalTo: headerLogoView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func makeNewPost(with postModel: UserPost, for user: ZoogramUser, completion: @escaping () -> Void) {
        var postModelToPost = postModel
        self.showMakingNewPostNotificationViewFor(username: user.username, with: postModel.image)
        task = Task {
            do {
                try await service.makeANewPost(post: postModelToPost) { progress in
                    Task { @MainActor in
                        self.updateProgressBar(progress: progress)
                    }
                }
                postModelToPost.author = user
                self.animateInsertionOfCreatedPost(post: postModelToPost)
                completion()
            } catch {
                self.notificationView?.removeFromSuperview()
                self.tableView.isUserInteractionEnabled = true
                self.tableView.removePlaceholderCell()
                self.show(error: error, title: "")
            }
        }
    }

    func removeNoPostsNotificationIfDisplayed() {
        self.tableView.removeNoPostsNotificationIfDisplayed()
    }

    private func showMakingNewPostNotificationViewFor(username: String, with postImage: UIImage?) {
        notificationView = NewPostProgressView(photo: postImage, username: username)
        notificationView?.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(notificationView!)
        notificationViewTopAnchor = notificationView!.topAnchor.constraint(equalTo: tableView.topAnchor)
        tableView.insertPlaceholderCell()
        tableView.isUserInteractionEnabled = false
        NSLayoutConstraint.activate([
            notificationViewTopAnchor,
            notificationView!.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            notificationView!.widthAnchor.constraint(equalTo: view.widthAnchor),
            notificationView!.heightAnchor.constraint(equalToConstant: PostTableViewCell.headerHeight)
        ])
    }

    private func updateProgressBar(progress: Progress?) {
        guard let notificationView = self.notificationView as? NewPostProgressView else {
            return
        }
        notificationView.setProgressToProgressBar(progress: progress)
    }

    private func animateInsertionOfCreatedPost(post: UserPost) {
        guard let notificationView = self.notificationView as? NewPostProgressView else {
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

    private func setupTableViewDidScrollAction() {
        tableView.didScrollAction = { offset, previousOffset in
            guard self.tableView.contentSize.height > self.tableView.frame.height
            else {
                if self.headerLogoTopConstraint.constant != 0 {
                    self.latestScrollDirection = .none
                    self.animateHeader(offset: 0, alpha: 1)
                }
                return
            }
            let absoluteTop: CGFloat = 0
            let absoluteBottom = self.tableView.contentSize.height - self.tableView.frame.size.height
            let scrollDifference = offset - previousOffset
            let isScrollingUp = scrollDifference < 0 && offset < absoluteBottom
            let isScrollingDown = scrollDifference > 0 && offset > absoluteTop
            var headerLogoTopOffset: CGFloat = self.headerLogoTopConstraint.constant

            if isScrollingDown {
                headerLogoTopOffset = max(-self.headerHeight, self.headerLogoTopConstraint.constant - abs(scrollDifference))
                let alphaPercentage = self.convertHeaderOffsetToAlphaPercentage(offset: headerLogoTopOffset)
                let logoAlpha = max(0.0, alphaPercentage)
                self.headerLogoView.alpha = logoAlpha
                self.latestScrollDirection = .downwards
            } else if isScrollingUp {
                headerLogoTopOffset = min(0, self.headerLogoTopConstraint.constant + abs(scrollDifference))
                let alphaPercentage = self.convertHeaderOffsetToAlphaPercentage(offset: headerLogoTopOffset)
                let logoAlpha = min(1.0, alphaPercentage)
                self.headerLogoView.alpha = logoAlpha
                self.latestScrollDirection = .upwards
            }

            if headerLogoTopOffset != self.headerLogoTopConstraint.constant {
                self.headerLogoTopConstraint.constant = headerLogoTopOffset
            }
        }
    }

    private func setupTableViewDidEndScrollAction() {
        tableView.didEndScrollingAction = {
            let currentLogoOffset = self.headerLogoTopConstraint.constant
            var alpha: CGFloat = self.headerLogoView.alpha
            var offset: CGFloat = self.headerLogoTopConstraint.constant

            if self.latestScrollDirection == .downwards && currentLogoOffset > -self.headerHeight {
                alpha = 0
                offset = -self.headerHeight
            } else if self.latestScrollDirection == .upwards && currentLogoOffset < 0 {
                alpha = 1
                offset = 0
            }

            if currentLogoOffset != offset {
                self.animateHeader(offset: offset, alpha: alpha)
            }
        }
    }

    private func animateHeader(offset: CGFloat, alpha: CGFloat) {
        self.headerLogoTopConstraint.constant = offset
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
            self.headerLogoView.alpha = alpha
        }
    }

    private func convertHeaderOffsetToAlphaPercentage(offset: CGFloat) -> CGFloat {
        return (100 - ((offset * 100) / -self.headerHeight)) / 100
    }

    private func handlePostCreationError(error: Error) {
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

    func shouldRefreshFeedIfNeeded() {
        task = Task {
            let numberOfRetrievedItems = await service.paginationManager.getNumberOfRetrievedItems()
            let numberOfAllItems = await service.paginationManager.getNumberOfAllItems()
            let numberOfItemsToPaginate = service.paginationManager.numberOfItemsToGetPerPagination
            let hasntRetrievedPosts = numberOfRetrievedItems == 0
            let numberOfReceivedItemsIsLessThanRequired = numberOfRetrievedItems < numberOfItemsToPaginate
            let hasntRetrievedAllPosts = numberOfRetrievedItems < numberOfAllItems
            let retrievedLessPostsThanRequired = numberOfReceivedItemsIsLessThanRequired && hasntRetrievedAllPosts

            if hasntRetrievedPosts || retrievedLessPostsThanRequired {
                self.tableView.refreshControl?.beginRefreshingManually()
                self.hideReloadButton()
            }
        }
    }

    private func showReloadButton(with error: Error) {
        view.addSubview(loadingErrorView)
        loadingErrorView.alpha = 1
        NSLayoutConstraint.activate([
            loadingErrorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingErrorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingErrorView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -60),
            loadingErrorView.heightAnchor.constraint(equalToConstant: 60)
        ])
        loadingErrorView.setDescriptionLabelText(error.localizedDescription)
        loadingErrorView.delegate = self
    }

    private func hideReloadButton() {
        UIView.animate(withDuration: 0.2) {
            self.loadingErrorView.alpha = 0
        } completion: { _ in
            self.loadingErrorView.removeFromSuperview()
        }
    }
}

extension HomeViewController: PostsTableViewProtocol {

    func showLoadingError(_ error: Error) {
        task = Task {
            let numberOfRetrievedItems = await service.paginationManager.getNumberOfRetrievedItems()
            if numberOfRetrievedItems == 0 {
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
        showProfile(of: user)
    }

    func didTapMenuButton(postModel: PostViewModel, indexPath: IndexPath) {
        showMenuForPost(postViewModel: postModel, onDelete: {
            self.tableView.deletePost(at: indexPath) { result in
                switch result {
                case .success:
                    self.tableView.showNoPostsNotificationIfNeeded()
                    sendNotificationToUpdateUserProfile()
                case .failure(let error):
                    self.showPopUp(issueText: error.localizedDescription)
                }
            }
        })
    }
}

extension HomeViewController: LoadingErrorViewDelegate {
    func didTapReloadButton() {
        hideReloadButton()
        tableView.refreshControl?.beginRefreshingManually()
    }
}
