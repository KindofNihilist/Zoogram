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



final class ProfileViewController: UIViewController {
    
    private var collectionView: UICollectionView?

    private var userData: User
    
    override func viewDidLoad() {
        setupConstraints()
        configureNavigationBar()
        setupCollectionView()
    }
    
    init(user: User) {
        self.userData = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureNavigationBar() {
        let settingsButton = UIBarButtonItem(image: UIImage(systemName: "gearshape"), style: .done, target: self, action: #selector(didTapSettingsButton))
        settingsButton.tintColor = .label
        navigationItem.rightBarButtonItem = settingsButton
        
        let label: UILabel = {
            let label = UILabel()
            label.text = userData.username
            label.font = UIFont.boldSystemFont(ofSize: 19)
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: label)
    }
    
    private func setupCollectionHeaders() {
        //Cell
        
    }
    
    private func setupCollectionView() {
        
//        let sectionsInsets = UIEdgeInsets(top: 0, left: 1, bottom: 0, right: 0)
//        let paddingSpace = sectionsInsets.left * 4
        let availableWidth = view.frame.width - 3
        let cellWidth = availableWidth / 3
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
//        layout.sectionInset = sectionsInsets
        layout.sectionInsetReference = .fromSafeArea
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView?.delegate = self
        collectionView?.dataSource = self

        //Register Cell
        collectionView?.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: PhotoCollectionViewCell.identifier)
        
        //Register Headers
        collectionView?.register(ProfileHeaderCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ProfileHeaderCollectionReusableView.identifier)

        collectionView?.register(ProfileTabsCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ProfileTabsCollectionReusableView.identifier)
        
        
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
        let vc = SettingsViewController(userData: userData)
        vc.title = "Settings"
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func setupConstraints() {
        
    }
}


extension ProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
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
            let tabsHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfileTabsCollectionReusableView.identifier, for: indexPath) as! ProfileTabsCollectionReusableView
            tabsHeader.delegate = self
            return tabsHeader
        }
        
        let profileHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfileHeaderCollectionReusableView.identifier, for: indexPath) as! ProfileHeaderCollectionReusableView
        profileHeader.delegate = self
        profileHeader.configure(with: userData)
        return profileHeader
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard section == 0 else {
            // Size of tabs section
            return CGSize(width: collectionView.frame.width, height: 45)
        }
        return CGSize(width: collectionView.frame.width, height: 185)
    }
    
}

extension ProfileViewController: ProfileHeaderCollectionReusableViewDelegate {
    func profileHeaderDidTapPostsButton(_ header: ProfileHeaderCollectionReusableView) {
        // center view on the posts section
        collectionView?.scrollToItem(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
    }
    
    func profileHeaderDidTapFollowingButton(_ header: ProfileHeaderCollectionReusableView) {
        // open viewcontroller with tableview of people user follows
        var testingData = [UserRelationship]()
        for i in 0...10 {
            testingData.append(UserRelationship(username: "Пухляш220_🐈", name: "Пухляш :3", type: i % 2 == 0 ? .following : .notFollowing))
        }
        
        let vc = ListViewController(data: testingData, viewKind: .following)
        vc.title = "Following"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func profileHeaderDidTapFollowersButton(_ header: ProfileHeaderCollectionReusableView) {
        // open viewcontroller with tableview of people following user
        var testingData = [UserRelationship]()
        for i in 0...10 {
            testingData.append(UserRelationship(username: "Пухляш220_🐈", name: "Пухляш :3", type: i % 2 == 0 ? .following : .notFollowing))
        }
        let vc = ListViewController(data: testingData, viewKind: .followers)
        vc.title = "Followers"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func profileHeaderDidTapEditProfileButton(_ header: ProfileHeaderCollectionReusableView) {
        // navigate to EditProfileViewController
        let vc = EditProfileViewController(userData: userData)
        present(UINavigationController(rootViewController: vc), animated: true)
    }
}

extension ProfileViewController: ProfileTabsCollectionReusableViewDelegate {
    func didTapGridTabButton() {
    
    }
    
    func didTapTaggedTabButton() {
        
    }
    
    
}
