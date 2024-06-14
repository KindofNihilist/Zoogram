//
//  SettingsViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 18.01.2022.
//

import UIKit
import FirebaseAuth

struct SettingsCellModel {
    let title: String
    let color: UIColor
    let handler: (() -> Void)
}

final class SettingsViewController: UIViewController {

    private var data = [[SettingsCellModel]]()

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = Colors.naturalSecondaryBackground
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.naturalSecondaryBackground
        configureModels()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.configureNavigationBarColor(with: Colors.naturalSecondaryBackground)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.configureNavigationBarColor(with: Colors.background)
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func configureModels() {
        let editProfileLocalizedTitle = String(localized: "Edit Profile")
        let bookmarksLocalizedTitile = String(localized: "Bookmarks")
        let logoutLocalizedTitle = String(localized: "Log Out")
        data.append([
            SettingsCellModel(title: editProfileLocalizedTitle, color: Colors.label) { [weak self] in
                self?.didTapEditProfile()
            },
            SettingsCellModel(title: bookmarksLocalizedTitile, color: Colors.label, handler: {
                self.didTapBookmarks()
            })
        ])
        data.append([SettingsCellModel(title: logoutLocalizedTitle, color: .systemRed) { [weak self] in
            self?.didTapLogOut()
            }
        ])
    }

    private func didTapEditProfile() {
        let service = UserDataValidationService()
        let profileEdditingViewController = ProfileEdditingViewController(service: service)
        let navVC = UINavigationController(rootViewController: profileEdditingViewController)
        navVC.modalPresentationStyle = .fullScreen
        present(navVC, animated: true)
    }

    private func didTapBookmarks() {
        let bookmarksAdapter = BookmarkedPostsService(
            bookmarksService: BookmarksSystemService.shared,
            likeSystemService: LikeSystemService.shared,
            userPostsService: UserPostsService.shared)
        let bookmarksVC = BookmarksViewController(service: bookmarksAdapter)
        navigationController?.pushViewController(bookmarksVC, animated: true)
    }

    private func didTapLogOut() {
        let logoutTitle = String(localized: "Log Out")
        let cancelTitle = String(localized: "Cancel")
        let localizedMessage = String(localized: "Are you sure you want to log out?")

        let logoutAlert = UIAlertController(title: logoutTitle, message: localizedMessage, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel)
        let logOutAction = UIAlertAction(title: logoutTitle, style: .destructive) { _ in
            do {
                try AuthenticationService.shared.signOut()
            } catch {
                self.show(error: error)
            }
        }
        logoutAlert.addAction(logOutAction)
        logoutAlert.addAction(cancelAction)
        present(logoutAlert, animated: true)
    }

}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let settingsCell = data[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = settingsCell.title
        content.textProperties.color = settingsCell.color
        content.textProperties.font = CustomFonts.regularFont(ofSize: 16)
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = Colors.naturalBackground
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = data[indexPath.section][indexPath.row]
        model.handler()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
