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
    
    private var collectionView: UICollectionView?

    private var viewModel = UserProfileViewModel()
    
    let settingsButton: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "gearshape"),
                                            style: .done,
                                            target: UserProfileViewController.self,
                                            action: #selector(didTapSettingsButton))
        barButtonItem.tintColor = .label
        return barButtonItem
    }()
    
    let userNicknameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 19)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        configureNavigationBar()
        setupCollectionView()
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        collectionView?.reloadData()
//    }
    
    init(for userID: String) {
        viewModel.getUserData(for: userID)
        print(viewModel.username)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    }
    
    @objc func didTapSettingsButton() {
        print("Tapped settings button")
        let vc = SettingsViewController()
        vc.title = "Settings"
        self.navigationController?.pushViewController(vc, animated: true)
    }
}


extension UserProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        }
        return 30
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as! PhotoCollectionViewCell
        
        cell.photoImageView.sd_setImage(with: URL(string: "https://images.pexels.com/photos/674010/pexels-photo-674010.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500"), completed: nil)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let vc = PostViewController(model: nil)
        vc.title = "Post"
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
       
        guard kind == UICollectionView.elementKindSectionHeader else {
            // if footer
            return UICollectionReusableView()
        }
        
        if indexPath.section == 1 {
            let tabsHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfileTabsReusableView.identifier, for: indexPath) as! ProfileTabsReusableView
            
            tabsHeader.delegate = self
            return tabsHeader
        }
        
        let profileHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfileHeaderReusableView.identifier, for: indexPath) as! ProfileHeaderReusableView
        
        profileHeader.delegate = self
        profileHeader.configure(name: viewModel.name,
                                bio: viewModel.bio,
                                profilePhotoURL: viewModel.profilePhotoURL,
                                postsCount: viewModel.postsCount,
                                followersCount: viewModel.followersCount,
                                followingCount: viewModel.followingCount)
        return profileHeader
    }
    
//    func reloadHeader() {
//        collectionView?.reloadData()
//    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard section == 0 else {
            // Size of tabs section
            return CGSize(width: collectionView.frame.width, height: 45)
        }
        return CGSize(width: collectionView.frame.width, height: 185)
    }
    
}

extension UserProfileViewController: ProfileHeaderDelegate {
    
    
    func profileHeaderDidTapPostsButton(_ header: ProfileHeaderReusableView) {
        // center view on the posts section
        collectionView?.scrollToItem(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
    }
    
    func profileHeaderDidTapFollowingButton(_ header: ProfileHeaderReusableView) {
        // open viewcontroller with tableview of people user follows
        var testingData = [UserRelationship]()
        for i in 0...10 {
            testingData.append(UserRelationship(username: "Пухляш220_🐈", name: "Пухляш :3", type: i % 2 == 0 ? .following : .notFollowing))
        }
        
        let vc = ListViewController(data: testingData, viewKind: .following)
        vc.title = "Following"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func profileHeaderDidTapFollowersButton(_ header: ProfileHeaderReusableView) {
        // open viewcontroller with tableview of people following user
        var testingData = [UserRelationship]()
        for i in 0...10 {
            testingData.append(UserRelationship(username: "Пухляш220_🐈", name: "Пухляш :3", type: i % 2 == 0 ? .following : .notFollowing))
        }
        let vc = ListViewController(data: testingData, viewKind: .followers)
        vc.title = "Followers"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func profileHeaderDidTapEditProfileButton(_ header: ProfileHeaderReusableView) {
        // navigate to ProfileEdditingViewController
        let vc = ProfileEdditingViewController()
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
