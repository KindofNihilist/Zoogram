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
    
    private var collectionView: UICollectionView!

    private var viewModel: UserProfileViewModel
    
    private var headerHeight: CGFloat = 0
    
    private var postTableViewController: PostViewController!
    
    private lazy var spinnerView = UIActivityIndicatorView()
    
    let settingsButton: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "gearshape"),
                                            style: .done,
                                            target: UserProfileViewController.self,
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
    
    lazy var collectionViewPlaceholder: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        if viewModel.isUserProfile {
            self.configureNavigationBar()
        }
        postTableViewController = PostViewController(posts: viewModel.userPosts, isUserProfile: viewModel.isUserProfile)
        setupCollectionView()
        NotificationCenter.default.addObserver(self, selector: #selector(onDataReceive), name: Notification.Name("ReceivedData"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(postDeleted), name: Notification.Name("PostDeleted"), object: nil)
//        viewModel.initializeViewModel(userID: viewModel.userID) {
//            if self.viewModel.isUserProfile {
//
//            }
//            self.collectionView.reloadData()
            
//        }
        
    }
    
    init(for userID: String, isUserProfile: Bool, isFollowed: FollowStatus) {
        viewModel = UserProfileViewModel(for: userID, followStatus: isFollowed, isUserProfile: isUserProfile)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func postDeleted(_ notification: Notification) {
        guard let index = notification.object as? Int else {
            print("couldn't cast notification object to Int type or object is nil")
            return
        }
        viewModel.userPosts.remove(at: index)
        collectionView.reloadData()
    }
    
    @objc private func onDataReceive() {
        print("DATA RECEIVED RELOADING TABLE VIEW")
        self.postTableViewController = PostViewController(posts: self.viewModel.userPosts, isUserProfile: viewModel.isUserProfile)
        collectionView.reloadData()
    }
    
    private func configureNavigationBar() {
        settingsButton.target = self
        settingsButton.action = #selector(didTapSettingsButton)
        setUserNickname()
        navigationItem.rightBarButtonItem = settingsButton
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: userNicknameLabel)
    }
    
    private func setUserNickname() {
        userNicknameLabel.text = viewModel.username
    }
    
    private func atachSpinnerView(to collectionViewHeader: UIView) {
        spinnerView.translatesAutoresizingMaskIntoConstraints = false
        collectionViewPlaceholder.addSubview(spinnerView)
        NSLayoutConstraint.activate([
            collectionViewPlaceholder.topAnchor.constraint(equalTo: collectionViewHeader.bottomAnchor),
            collectionViewPlaceholder.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor),
            collectionViewPlaceholder.widthAnchor.constraint(equalTo: collectionView.widthAnchor),
            
            spinnerView.heightAnchor.constraint(equalToConstant: 25),
            spinnerView.widthAnchor.constraint(equalToConstant: 25),
            spinnerView.topAnchor.constraint(equalTo: collectionViewPlaceholder.topAnchor),
            spinnerView.bottomAnchor.constraint(equalTo: collectionViewPlaceholder.bottomAnchor),
            spinnerView.centerXAnchor.constraint(equalTo: collectionViewPlaceholder.centerXAnchor)
        ])
        spinnerView.startAnimating()
    }
    
    private func createNoPostsView() {
        spinnerView.removeFromSuperview()
        let noPostsAlert = NoPostsAlertView()
        noPostsAlert.translatesAutoresizingMaskIntoConstraints = false
        collectionViewPlaceholder.addSubview(noPostsAlert)
        NSLayoutConstraint.activate([
            noPostsAlert.topAnchor.constraint(equalTo: collectionViewPlaceholder.topAnchor),
            noPostsAlert.bottomAnchor.constraint(equalTo: collectionViewPlaceholder.bottomAnchor),
            noPostsAlert.widthAnchor.constraint(equalTo: collectionViewPlaceholder.widthAnchor)
        ])
    }
    
    private func setupCollectionView() {
        let availableWidth = view.frame.width - 3
        let cellWidth = availableWidth / 3
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        layout.sectionInsetReference = .fromSafeArea
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView?.delegate = self
        collectionView?.dataSource = self 

        //Register Cell
        collectionView?.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: PhotoCollectionViewCell.identifier)
        
        //Register Headers
        collectionView?.register(ProfileHeaderReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ProfileHeaderReusableView.identifier)

        collectionView?.register(ProfileTabsReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ProfileTabsReusableView.identifier)
        
        guard let collectionView = collectionView else {
            return
        }
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        collectionView.addSubview(collectionViewPlaceholder)
    }
    
    // MARK: Profile header setup
    func createProfileHeader(for collectionView: UICollectionView, ofKind: String, for indexPath: IndexPath) -> UICollectionReusableView {
        let profileHeader = collectionView.dequeueReusableSupplementaryView(ofKind: ofKind, withReuseIdentifier: ProfileHeaderReusableView.identifier, for: indexPath) as! ProfileHeaderReusableView
        profileHeader.delegate = self
        profileHeader.configure(name: viewModel.name,
                                bio: viewModel.bio,
                                profilePicture: viewModel.profilePhoto,
                                postsCount: viewModel.postsCount,
                                followersCount: viewModel.followersCount,
                                followingCount: viewModel.followingCount,
                                isFollowed: viewModel.isFollowed,
                                isUserProfile: viewModel.isUserProfile)
        self.headerHeight = profileHeader.frame.height
        return profileHeader
    }
    
    func createTabsHeader(for collectionView: UICollectionView, ofKind: String, for indexPath: IndexPath) -> UICollectionReusableView {
        let profileTabsHeader = collectionView.dequeueReusableSupplementaryView(ofKind: ofKind, withReuseIdentifier: ProfileTabsReusableView.identifier, for: indexPath) as! ProfileTabsReusableView
        
        
        profileTabsHeader.delegate = self
        
        if viewModel.isInitialized && !viewModel.userPosts.isEmpty {
            collectionViewPlaceholder.removeFromSuperview()
        } else if !viewModel.isInitialized {
            atachSpinnerView(to: profileTabsHeader)
        } else {
            createNoPostsView()
        }
        
        return profileTabsHeader
    }
    
    @objc func didTapSettingsButton() {
        print("Tapped settings button")
        let vc = SettingsViewController()
        vc.title = "Settings"
        self.navigationController?.pushViewController(vc, animated: true)
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
        return viewModel.userPosts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as! PhotoCollectionViewCell
        
        let post = viewModel.userPosts[indexPath.row]
        
        cell.photoImageView.sd_setImage(with: URL(string: post.photoURL)) { image, _, _, _  in
            if let downloadedImage = image {
                self.viewModel.userPosts[indexPath.row].image = downloadedImage
            }
        }
//        print("Cell \(indexPath.row) created")
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        collectionView.deselectItem(at: indexPath, animated: true)
        postTableViewController.focusTableViewOnPostWith(index: IndexPath(row: 0, section: indexPath.row))
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
        
        if section == 0 {
            let headerView = self.collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader, at: IndexPath(row: 0, section: section))
            
            return headerView.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        }
        
        return CGSize(width: 0, height: 0)
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let position = scrollView.contentOffset.y
        
        if position > (collectionView.contentSize.height - 100 - scrollView.frame.size.height) {
            guard !viewModel.isPaginating else {
                //we already fetching more data
                return
            }
            viewModel.getMoreUserPosts { paginatedPosts in
                self.collectionView.reloadData()
                self.postTableViewController.addPaginatedUserPosts(posts: paginatedPosts)
            }
        }
    }
    
}

// MARK: ProfileHeaderDelegate
extension UserProfileViewController: ProfileHeaderDelegate {
    
    func followButtonTapped(_ header: ProfileHeaderReusableView, followCompletion: @escaping (FollowStatus) -> Void) {
        guard viewModel.isInitialized else {
            return
        }
        print("Follow tapped")
        viewModel.followUser { success in
            if success {
                print("Succesfully followed")
                followCompletion(.following)
            } else {
                print("Unnable to follow, try again later")
            }
            
        }
    }
    
    func unfollowButtonTapped(_ header: ProfileHeaderReusableView, unfollowCompletion: @escaping (FollowStatus) -> Void) {
        guard viewModel.isInitialized else {
            return
        }
        print("Unfollow tapped")
        viewModel.unfollowUser { success in
            if success {
                print("Succesfully unfollowed")
                unfollowCompletion(.notFollowing)
            } else {
                print("Unnable to unfollow, try again later")
            }
        }
    }
    
    func postsButtonTapped(_ header: ProfileHeaderReusableView) {
        guard viewModel.isInitialized else {
            return
        }
        // center view on the posts section
        collectionView?.scrollToItem(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
    }
    
    func followingButtonTapped(_ header: ProfileHeaderReusableView) {
        guard viewModel.isInitialized else {
            return
        }
        // open tableview of people user follows
        let vc = FollowListViewController(for: viewModel.userID, isUserProfile: viewModel.isUserProfile , viewKind: .following)
        vc.title = "Following"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func followersButtonTapped(_ header: ProfileHeaderReusableView) {
        guard viewModel.isInitialized else {
            return
        }
        // open viewcontroller with tableview of people following user
        let vc = FollowListViewController(for: viewModel.userID, isUserProfile: viewModel.isUserProfile, viewKind: .followers)
        vc.title = "Followers"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func editProfileButtonTapped(_ header: ProfileHeaderReusableView) {
        guard viewModel.isInitialized else {
            return
        }
        // navigate to ProfileEdditingViewController
        let vc = ProfileEdditingViewController(profileImage: viewModel.profilePhoto)
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true)
    }
}


extension UserProfileViewController: ProfileTabsCollectionViewDelegate {
    func didTapGridTabButton() {
    
    }
    
    func didTapTaggedTabButton() {
        
    }
    
    
}

extension UserProfileViewController: ProfileEdditingProtocol {
    func reloadChangedData() {
        print("RELOADING DATA")
        DispatchQueue.main.async {
            self.setUserNickname()
            self.collectionView?.reloadData()
        }
    }
}
