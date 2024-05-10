//
//  ProfileEdditingViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 19.01.2022.
//
import UIKit

protocol ProfileEdditingViewDelegate: ProfileEdditingCellDelegate, ProfilePictureViewDelegate, TableViewTextViewDelegate {}

class ProfileEdditingViewController: UIViewController {

    let viewModel: ProfileEdditingViewModel
    lazy var factory = ProfileEdditingFactory(tableView: self.tableView)
    var dataSource: DefaultTableViewDataSource?
    lazy var imagePicker = UIImagePickerController()

    private var shouldUpdateProfilePicture: Bool = false

    private let tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = Colors.naturalSecondaryBackground
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 0
        tableView.keyboardDismissMode = .interactive
        return tableView
    }()

    init(userProfileViewModel: UserProfileViewModel, service: UserDataValidationServiceProtocol) {
        self.viewModel = ProfileEdditingViewModel(userViewModel: userProfileViewModel, service: service)
        super.init(nibName: nil, bundle: nil)
        factory.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        setupConstraints()
        title = String(localized: "Editing")
        navigationController?.navigationBar.titleTextAttributes = [.font: CustomFonts.boldFont(ofSize: 16)]
        view.backgroundColor = Colors.naturalSecondaryBackground
        navigationController?.navigationBar.configureNavigationBarColor(with: Colors.naturalSecondaryBackground)
        configureNavigationBar()
        viewModel.configureModels()
        setupFactory()
        setupEdditingInteruptionGestures()
    }

    override func viewWillAppear(_ animated: Bool) {
        if shouldUpdateProfilePicture {
            factory.updateProfilePicture(with: viewModel.newProfilePicture!)
        }
    }

    private func setupFactory() {
        let sections = factory.buildSections(
            profilePicture: viewModel.currentProfilePicture,
            profileInfoModels: viewModel.generalInfoModels,
            privateInfoModels: viewModel.privateInfoModels)
        dataSource = DefaultTableViewDataSource(sections: factory.sections)
        tableView.delegate = dataSource
        tableView.dataSource = dataSource
        tableView.reloadData()
    }

    private func configureNavigationBar() {
        showSaveButton()
        showCancelButton()
    }

    func showCancelButton() {
        let cancelButton = UIBarButtonItem(
            title: String(localized: "Cancel"),
            style: .plain,
            target: self,
            action: #selector(didTapCancel))

        cancelButton.setTitleTextAttributes([.font: CustomFonts.boldFont(ofSize: 16)], for: .normal)
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.leftBarButtonItem?.tintColor = Colors.label
    }

    func showSaveButton() {
        let saveButton = UIBarButtonItem(
            title: String(localized: "Save"),
            style: .done,
            target: self,
            action: #selector(didTapSave))
        saveButton.setTitleTextAttributes([.font: CustomFonts.boldFont(ofSize: 16)], for: .normal)
        navigationItem.rightBarButtonItem = saveButton
    }

    func showLoadingIndicator() {
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.frame = CGRect(x: 0, y: 0, width: 35, height: 25)
        loadingIndicator.color = Colors.label
        loadingIndicator.startAnimating()
        let barItem = UIBarButtonItem(customView: loadingIndicator)
        self.navigationItem.rightBarButtonItem = barItem
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        ])
    }

    @objc func didTapSave() {
        self.showLoadingIndicator()
        Task { @MainActor in
            do {
                try await viewModel.checkIfNewValuesAreValid()
                try await viewModel.saveChanges()
            } catch {
                self.showPopUp(issueText: error.localizedDescription)
                self.showSaveButton()
            }
        }
    }

    @objc func didTapCancel() {
        self.dismiss(animated: true)
    }

    @objc func resignResponder() {
        self.tableView.resignFirstResponder()
    }
}

extension ProfileEdditingViewController: ProfileEdditingViewDelegate {

    func didUpdateTextView() {
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    func didUpdateModel(_ model: EditProfileFormModel) {
        viewModel.hasEdditedUserProfile(data: model)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.viewModel.newProfilePicture = selectedImage
            self.shouldUpdateProfilePicture = true
            self.viewModel.hasChangedProfilePic = true
        }
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
