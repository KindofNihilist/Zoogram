//
//  DiscoverViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//

import UIKit
import SDWebImage

class DiscoverViewController: UIViewController {
    
    let viewModel = DiscoverViewModel()
    
    private let spinnerView: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.isHidden = true
        return spinner
    }()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.autocapitalizationType = .none
        searchBar.placeholder = "Search users"
        searchBar.returnKeyType = .search
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(SearchedUserTableViewCell.self, forCellReuseIdentifier: SearchedUserTableViewCell.identifier)
        return tableView
    }()
    
    private var collectionView: UICollectionView?
    
    override func viewDidLoad() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.topItem?.titleView = searchBar
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
//        navigationController?.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gobackwards"), style: .plain, target: self, action: #selector(reloadTableView))
        
        view.addSubviews(tableView, spinnerView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            spinnerView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            spinnerView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            spinnerView.heightAnchor.constraint(equalToConstant: 30),
            spinnerView.widthAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: view.frame.width/3, height: view.frame.width/3)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        guard let collectionView = collectionView else {
            return
        }
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
    
}

extension DiscoverViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
}

extension DiscoverViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        spinnerView.isHidden = false
        spinnerView.startAnimating()
        
        viewModel.searchUser(for: searchText) {
            self.tableView.reloadData()
            self.spinnerView.isHidden = true
            self.spinnerView.stopAnimating()
        }
    }
    
    
}

extension DiscoverViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.foundUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = viewModel.foundUsers[indexPath.row]
        print(user.username)
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchedUserTableViewCell.identifier, for: indexPath) as! SearchedUserTableViewCell
        
        cell.usernameLabel.text = user.username
        cell.nameLabel.text = user.name
        cell.profileImageView.sd_setImage(with: URL(string: user.profilePhotoURL))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = viewModel.foundUsers[indexPath.row]
        print("USER SELECTED:", user.username)
        let userProfileViewController = UserProfileViewController(for: user.userID, isUserProfile: user.isUserProfile, isFollowed: user.isFollowed)
        userProfileViewController.title = user.username
        self.navigationController?.pushViewController(userProfileViewController, animated: true)
    }
    
    
}

extension DiscoverViewController: UISearchTextFieldDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
}
