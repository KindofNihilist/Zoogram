//
//  BookmarksTableView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 06.03.2023.
//

import UIKit

class BookmarkedTableViewController: UIViewController {

    private var bookmarkedPosts = [PostViewModel]()

    var service: PostsService!

    private var collectionView: UICollectionView?

    private var postsTableView: PostsTableView!

    private lazy var spinnerView = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        self.title = "Bookmarks"
        createSpinnerView()
    }

    override func viewWillAppear(_ animated: Bool) {

    }

    override func viewDidAppear(_ animated: Bool) {
        service.getPosts { posts in
            if posts.isEmpty {
                self.createNoPostsView()
            } else {
                self.bookmarkedPosts = posts
                self.postsTableView = {
                    let tableView = PostsTableView(service: self.service, posts: posts)
                    tableView.allowsSelection = false
                    tableView.separatorStyle = .none
                    return tableView
                }()
                self.collectionView?.reloadData()
            }
            self.spinnerView.stopAnimating()
            self.spinnerView.removeFromSuperview()
        }
    }

    private func createSpinnerView() {
        spinnerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinnerView)
        NSLayoutConstraint.activate([
            spinnerView.heightAnchor.constraint(equalToConstant: 50),
            spinnerView.widthAnchor.constraint(equalToConstant: 50),
            spinnerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            spinnerView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        spinnerView.startAnimating()
    }

    private func createNoPostsView() {
        collectionView?.isHidden = true
        let noBookmarksView = PlaceholderView(imageName: "bookmark.fill",
                                              text: "Bookmarked posts will be displayed here")
        noBookmarksView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noBookmarksView)
        NSLayoutConstraint.activate([
            noBookmarksView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 150),
            noBookmarksView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noBookmarksView.heightAnchor.constraint(equalToConstant: 200),
            noBookmarksView.widthAnchor.constraint(equalTo: view.widthAnchor)
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

        // Register Cell
        collectionView?.register(PhotoCollectionViewCell.self,
                                 forCellWithReuseIdentifier: PhotoCollectionViewCell.identifier)

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
}

// MARK: CollectionView Delegate
extension BookmarkedTableViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bookmarkedPosts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier,
                                                      for: indexPath) as? PhotoCollectionViewCell
        let post = bookmarkedPosts[indexPath.row]
        print("POST:", post)
        cell?.photoImageView.image = post.postImage
        return cell ?? UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //        collectionView.deselectItem(at: indexPath, animated: true)
//        postTableViewController.focusTableViewOnPostWith(index: indexPath)
//        navigationController?.pushViewController(postTableViewController, animated: true)
    }

//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let position = scrollView.contentOffset.y
//
//        if position > (collectionView.contentSize.height - 100 - scrollView.frame.size.height) {
//            guard !viewModel.isPaginating else {
//                //we already fetching more data
//                return
//            }
//            viewModel.getMoreUserPosts { paginatedPosts in
//                print("Paginated posts")
//                self.collectionView.reloadData()
//                self.postTableViewController.addPaginatedPosts(posts: paginatedPosts)
//            }
//        }
//    }
}
