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
    
    var service: UserProfileServiceAPIAdapter!
    
    private var viewModel = UserProfileViewModel()
    
    private var collectionView: UICollectionView!
    
    private var headerHeight: CGFloat = 0
    
    private var postTableViewController: PostViewController!
    
    private var profileHeaderView: ProfileHeaderReusableView?
    
    private lazy var spinnerView = UIActivityIndicatorView()
    
    let settingsButton: UIBarButtonItem = {
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
    
    init(isTabBarItem: Bool) {
        super.init(nibName: nil, bundle: nil)
        
        if isTabBarItem {
            self.configureNavigationBar()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        setupCollectionView()
        self.postTableViewController = PostViewController(posts: viewModel.posts)
    
        NotificationCenter.default.addObserver(self, selector: #selector(postDeleted), name: Notification.Name("PostDeleted"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        service.getUserProfileViewModel { viewModel in
            print("inside user profile get profile view model")
            self.viewModel = viewModel
            self.collectionView.reloadData()
        }
        
        service.getPosts { posts in
            print("inside User Profile get posts")
            print("Posts retrived for profile: \(posts.count)")
            self.viewModel.posts = posts
            self.collectionView.reloadData()
        }
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
    
    
    //MARK: CollectionView Setup
    private func setupCollectionView() {
        let layout = (viewModel.postsCount > 0) ? createCollectionViewLayoutFor(numberOfCells: 3) : createCollectionViewLayoutFor(numberOfCells: 1)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView?.delegate = self
        collectionView?.dataSource = self
        
        collectionView?.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: PhotoCollectionViewCell.identifier)
        collectionView?.register(ProfileHeaderReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ProfileHeaderReusableView.identifier)
        collectionView?.register(ProfileTabsReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ProfileTabsReusableView.identifier)
        collectionView?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "NoPostsCell")
        collectionView?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "SpinnerViewCell")
        
        guard let collectionView = collectionView else {
            return
        }
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
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
    
    private func createSpinnerViewFor(collectionView: UICollectionView, at indexPath: IndexPath) -> UICollectionViewCell {
        let spinnerCell = collectionView.dequeueReusableCell(withReuseIdentifier: "SpinnerViewCell", for: indexPath)
        spinnerView.translatesAutoresizingMaskIntoConstraints = false
        spinnerCell.addSubview(spinnerView)
        NSLayoutConstraint.activate([
            spinnerView.heightAnchor.constraint(equalToConstant: 25),
            spinnerView.widthAnchor.constraint(equalToConstant: 25),
            spinnerView.topAnchor.constraint(equalTo: spinnerCell.topAnchor, constant: 25),
            spinnerView.centerXAnchor.constraint(equalTo: spinnerCell.centerXAnchor)
        ])
        spinnerView.startAnimating()
        return spinnerCell
    }
    
    private func createCollectionViewLayoutFor(numberOfCells: Int) -> UICollectionViewFlowLayout {
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
        spinnerView.removeFromSuperview()
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NoPostsCell", for: indexPath)
//        cell.backgroundColor = .systemCyan
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
        
        let profileHeader = collectionView.dequeueReusableSupplementaryView(ofKind: ofKind, withReuseIdentifier: ProfileHeaderReusableView.identifier, for: indexPath) as! ProfileHeaderReusableView
        profileHeader.delegate = self
        
        profileHeader.configureWith(viewModel: self.viewModel)
        
        self.headerHeight = profileHeader.frame.height
        self.profileHeaderView = profileHeader
        return profileHeader
    }
    
    func createTabsHeader(for collectionView: UICollectionView, ofKind: String, for indexPath: IndexPath) -> UICollectionReusableView {
        let profileTabsHeader = collectionView.dequeueReusableSupplementaryView(ofKind: ofKind, withReuseIdentifier: ProfileTabsReusableView.identifier, for: indexPath) as! ProfileTabsReusableView
        
        profileTabsHeader.delegate = self
        
        return profileTabsHeader
    }
    
    func setTopCollectionViewVisibleContent() {
        self.collectionView.setContentOffset(CGPointZero, animated: true)
    }
    
    @objc private func didTapSettingsButton() {
        let vc = SettingsViewController()
        vc.hidesBottomBarWhenPushed = true
        vc.title = "Settings"
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func postDeleted(_ notification: Notification) {
        guard let index = notification.object as? Int else {
            print("couldn't cast notification object to Int type or object is nil")
            return
        }
        viewModel.posts.remove(at: index)
        collectionView.reloadData()
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
        
        //if posts hasn't downloaded yet but posts count is bigger than 0 - returns 12 blank cells, otherwise returns 0
        guard viewModel.posts.isEmpty != true else {
            return viewModel.postsCount > 0 ? 12 : 0
        }
        
        return viewModel.posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard viewModel.posts.isEmpty != true else {
            if viewModel.postsCount == 0 {
                return createNoPostsViewCellFor(collectionView: collectionView, indexPath: indexPath)
            } else {
                return createSpinnerViewFor(collectionView: collectionView, at: indexPath)
            }
            
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as! PhotoCollectionViewCell
        
        let post = viewModel.posts[indexPath.row]
        
        cell.photoImageView.image = post.postImage

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard viewModel.posts.isEmpty != true else {
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
        
        return createProfileHeader(for: collectionView, ofKind: kind, for: indexPath)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        guard section == 0 else {
            // Size of tabs section
            return CGSize(width: collectionView.frame.width, height: 45)
        }
        
        let headerView = self.collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader, at: IndexPath(row: 0, section: section))

        return headerView.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let position = scrollView.contentOffset.y
        
        if position > (collectionView.contentSize.height - 100 - scrollView.frame.size.height) {
            service.getMorePosts { paginatedPosts in
                self.viewModel.posts.append(contentsOf: paginatedPosts)
            }
        }
    }
}

// MARK: ProfileHeaderDelegate
extension UserProfileViewController: ProfileHeaderDelegate {
    
    func followButtonTapped(_ header: ProfileHeaderReusableView) {
        service.followUser { followStatus in
            self.viewModel.user.followStatus = followStatus
            header.switchFollowUnfollowButton(followStatus: followStatus)
        }
    }
    
    func unfollowButtonTapped(_ header: ProfileHeaderReusableView) {
        service.unfollowUser { followStatus in
            self.viewModel.user.followStatus = followStatus
            header.switchFollowUnfollowButton(followStatus: followStatus)
        }
    }
    
    func postsButtonTapped(_ header: ProfileHeaderReusableView) {
        guard viewModel.posts.isEmpty != true else {
            return
        }
        // center view on the posts section
        collectionView?.scrollToItem(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
    }
    
    func followingButtonTapped(_ header: ProfileHeaderReusableView) {
        let user = viewModel.user
        // open tableview of people user follows
        let vc = FollowListViewController(for: user.userID, isUserProfile: viewModel.isCurrentUserProfile , viewKind: .following)
        vc.title = "Following"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func followersButtonTapped(_ header: ProfileHeaderReusableView) {
        let user = viewModel.user
        // open viewcontroller with tableview of people following user
        let vc = FollowListViewController(for: user.userID, isUserProfile: viewModel.isCurrentUserProfile, viewKind: .followers)
        vc.title = "Followers"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func editProfileButtonTapped(_ header: ProfileHeaderReusableView) {
        guard let photo = viewModel.user.profilePhoto else {
            return
        }
        // navigate to ProfileEdditingViewController
        let vc = ProfileEdditingViewController(profileImage: photo)
        present(UINavigationController(rootViewController: vc), animated: true)
    }
}


extension UserProfileViewController: ProfileTabsCollectionViewDelegate {
    func didTapGridTabButton() {
        
    }
    
    func didTapTaggedTabButton() {
        
    }
    
    
}

