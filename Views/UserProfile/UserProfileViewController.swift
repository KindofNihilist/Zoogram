//
//  ProfileViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//
import SDWebImage
import FirebaseAuth
import UIKit
import AVFoundation

final class UserProfileViewController: UIViewController {

    var service: UserProfileService!

    private var viewModel = UserProfileViewModel()

    private var collectionView: UICollectionView!

    private var postTableViewController: PostViewController

    private lazy var settingsButton: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal"),
                                            style: .done,
                                            target: self,
                                            action: #selector(didTapSettingsButton))
        barButtonItem.tintColor = .label
        return barButtonItem
    }()

    lazy var userNicknameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 19)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(service: UserProfileService, user: ZoogramUser? = nil, isTabBarItem: Bool) {
        self.service = service
        self.viewModel.insertUserIfPreviouslyObtained(user: user)
        self.postTableViewController = PostViewController(posts: viewModel.posts.value, service: self.service)
        super.init(nibName: nil, bundle: nil)
        
        service.getUserProfileViewModel { viewModel in
            self.viewModel.updateValuesWithViewModel(viewModel)
            if isTabBarItem {
                self.configureNavigationBar()
            }
        }

        self.viewModel.posts.bind { posts in
            self.postTableViewController.updatePostsArrayWith(posts: posts)
            print("posts value changed")
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        setupCollectionView()
        service.getPosts { posts in
            self.viewModel.posts.value = posts
            self.changeCollectionViewLayoutIfNeeded()
        }
    }


    func refreshProfileData() {
        service.getUserProfileViewModel { viewModel in
            self.viewModel.updateValuesWithViewModel(viewModel)
            self.configureNavigationBar()
        }

        service.getPosts { posts in
            self.viewModel.posts.value = posts
            self.changeCollectionViewLayoutIfNeeded()
        }
    }

    func getCurrentUserProfile() -> ZoogramUser {
        return viewModel.user
    }

    private func changeCollectionViewLayoutIfNeeded() {
        let layout = createCollectionViewLayout()
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.setCollectionViewLayout(layout, animated: false)
    }

    private func configureNavigationBar() {
        settingsButton.target = self
        settingsButton.action = #selector(didTapSettingsButton)
        setUserNickname()
        navigationItem.rightBarButtonItem = settingsButton
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: userNicknameLabel)
    }

    private func setUserNickname() {
        userNicknameLabel.text = viewModel.user.username
    }

    private func updateTableViewPosts() {
        let posts = viewModel.posts.value
        self.postTableViewController.updatePostsArrayWith(posts: posts)
    }

    // MARK: CollectionView Setup
    private func setupCollectionView() {

        let layout = createCollectionViewLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView?.delegate = self
        collectionView?.dataSource = self

        collectionView?.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: PhotoCollectionViewCell.identifier)
        collectionView?.register(ProfileHeaderReusableView.self,
                                 forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                 withReuseIdentifier: ProfileHeaderReusableView.identifier)
        collectionView?.register(ProfileTabsReusableView.self,
                                 forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                 withReuseIdentifier: ProfileTabsReusableView.identifier)
        collectionView?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "NoPostsCell")
        collectionView?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "BlankCell")

        guard let collectionView = collectionView else {
            return
        }

        collectionView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func createFooterSpinnerView() -> UIView {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 70))
        footerView.backgroundColor = .systemCyan
        let spinner = UIActivityIndicatorView(style: .medium)
        footerView.addSubview(spinner)
        spinner.center = footerView.center
        spinner.startAnimating()
        return footerView
    }

    private func createBlankCellFor(collectionView: UICollectionView, at indexPath: IndexPath) -> UICollectionViewCell {
        let blankCell = collectionView.dequeueReusableCell(withReuseIdentifier: "BlankCell", for: indexPath)
        blankCell.backgroundColor = .systemGray5
        return blankCell
    }

    private func createCollectionViewLayout() -> UICollectionViewFlowLayout {
        let numberOfCells = viewModel.user.hasPosts ? 3 : 1

        let availableWidth = view.frame.width - CGFloat(numberOfCells)
        let cellWidth = availableWidth / CGFloat(numberOfCells)

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        layout.sectionInsetReference = .fromSafeArea
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        return layout
    }

    private func createNoPostsViewCellFor(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        //        spinnerView.removeFromSuperview()
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NoPostsCell", for: indexPath)
        let noPostsAlert = PlaceholderView(imageName: "camera", text: "No Posts Yet")
        noPostsAlert.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(noPostsAlert)
        NSLayoutConstraint.activate([
            noPostsAlert.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            noPostsAlert.heightAnchor.constraint(equalToConstant: 150),
            noPostsAlert.widthAnchor.constraint(equalTo: cell.contentView.widthAnchor)
        ])
        return cell
    }

    // MARK: Profile header setup
    func createProfileHeader(for collectionView: UICollectionView, ofKind: String, for indexPath: IndexPath) -> UICollectionReusableView {

        let profileHeader: ProfileHeaderReusableView = collectionView.dequeueReusableView(withIdentifier: ProfileHeaderReusableView.identifier, ofKind: ofKind, for: indexPath)
        profileHeader.delegate = self
        print("Kind: ", ofKind)
        print("Index path the headerView is created for: ", indexPath)
        profileHeader.configureWith(viewModel: self.viewModel)

        return profileHeader
    }

    func createTabsHeader(for collectionView: UICollectionView, ofKind: String, for indexPath: IndexPath) -> UICollectionReusableView {

        let profileTabsHeader: ProfileTabsReusableView = collectionView.dequeueReusableView(withIdentifier: ProfileTabsReusableView.identifier, ofKind: ofKind, for: indexPath)
        profileTabsHeader.delegate = self

        return profileTabsHeader
    }

    func setTopCollectionViewVisibleContent() {
        self.collectionView.setContentOffset(CGPoint.zero, animated: true)
    }

    @objc private func didTapSettingsButton() {
        let settingsVC = SettingsViewController()
        settingsVC.hidesBottomBarWhenPushed = true
        settingsVC.title = "Settings"
        self.navigationController?.pushViewController(settingsVC, animated: true)
    }
}

// MARK: CollectionViewDelegate

extension UserProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        }
        // if posts hasn't downloaded yet but posts count is bigger than 0 - returns 12 blank cells, otherwise returns 0
        guard viewModel.posts.value.isEmpty != true else {
            return viewModel.user.hasPosts ? 12 : 1
        }

        return viewModel.posts.value.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard viewModel.posts.value.isEmpty != true else {

            if viewModel.user.hasPosts == false {
                return createNoPostsViewCellFor(collectionView: collectionView, indexPath: indexPath)
            } else {
                return createBlankCellFor(collectionView: collectionView, at: indexPath)
            }
        }

        let cell: PhotoCollectionViewCell = collectionView.dequeue(withIdentifier: PhotoCollectionViewCell.identifier,
                                                              for: indexPath)
        let post = viewModel.posts.value[indexPath.row]
        cell.photoImageView.image = post.postImage

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard viewModel.posts.value.isEmpty != true else {
            return
        }
        postTableViewController.focusTableViewOnPostWith(index: indexPath)
        navigationController?.pushViewController(postTableViewController, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        if indexPath.section == 1 {
            return createTabsHeader(for: collectionView, ofKind: kind, for: indexPath)
        }

        print("Header view indexPath: ", indexPath)
        return createProfileHeader(for: collectionView, ofKind: kind, for: indexPath)

    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        guard section == 0 else {
            // Size of tabs section
            return CGSize(width: collectionView.frame.width, height: 45)
        }

        let headerView = self.collectionView(collectionView,
                                             viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader,
                                             at: IndexPath(row: 0, section: section))

        return headerView.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width,
                                                         height: UIView.layoutFittingCompressedSize.height),
                                                  withHorizontalFittingPriority: .required,
                                                  verticalFittingPriority: .fittingSizeLevel)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let position = scrollView.contentOffset.y

        if position > (collectionView.contentSize.height - 100 - scrollView.frame.size.height) {
            service.getMorePosts { paginatedPosts in
                if let unwrappedPosts = paginatedPosts {
                    self.viewModel.posts.value.append(contentsOf: unwrappedPosts)
                    self.collectionView.reloadData()
                    self.updateTableViewPosts()
                }
            }
        }
    }
}

// MARK: ProfileHeaderDelegate
extension UserProfileViewController: ProfileHeaderDelegate {

    func postsButtonTapped() {
        guard viewModel.posts.value.isEmpty != true else {
            return
        }
        // center view on the posts section
        collectionView?.scrollToItem(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
    }

    func followingButtonTapped() {
        let user = viewModel.user
        // open tableview of people user follows
        let followListVC = FollowListViewController(for: user.userID,
                                                    isUserProfile: viewModel.isCurrentUserProfile,
                                                    viewKind: .following)
        followListVC.title = "Following"
        navigationController?.pushViewController(followListVC, animated: true)
    }

    func followersButtonTapped() {
        let user = viewModel.user
        // open viewcontroller with tableview of people following user
        let followListVC = FollowListViewController(for: user.userID,
                                                    isUserProfile: viewModel.isCurrentUserProfile,
                                                    viewKind: .followers)
        followListVC.title = "Followers"
        navigationController?.pushViewController(followListVC, animated: true)
    }

    func editProfileButtonTapped() {
        let profileEditingVC = ProfileEdditingViewController(userProfileViewModel: self.viewModel)
        present(UINavigationController(rootViewController: profileEditingVC), animated: true)
    }

    func followButtonTapped(completion: @escaping (FollowStatus) -> Void) {
        service.followUser { [weak self] followStatus in
            self?.viewModel.user.followStatus = followStatus
            completion(followStatus)
        }
    }

    func unfollowButtonTapped(completion: @escaping (FollowStatus) -> Void) {
        service.unfollowUser { [weak self] followStatus in
            self?.viewModel.user.followStatus = followStatus
            completion(followStatus)
        }
    }
}

extension UserProfileViewController: ProfileTabsCollectionViewDelegate {
    func didTapGridTabButton() {

    }

    func didTapTaggedTabButton() {

    }
}

extension UserProfileViewController: UserProfilePostsTableViewProtocol {
    func updateUserProfileData() {
        self.refreshProfileData()
    }
}
