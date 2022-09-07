//
//  EditProfileViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 19.01.2022.
//

import SDWebImage
import UIKit

enum profileFormKind {
    case name, username, bio, phone, email, gender
}

struct EditProfileFormModel {
    let label: String
    let placeholder: String
    var value: String?
    let formKind: profileFormKind
}

class EditProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var models = [[EditProfileFormModel]]()
    
    private var changedValues = [String: Any]()
    
    private var hasChangedProfilePic: Bool = false
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(FormTableViewCell.self, forCellReuseIdentifier: FormTableViewCell.identifier)
        tableView.register(EditProfileSectionHeader.self, forHeaderFooterViewReuseIdentifier: EditProfileSectionHeader.identifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        tableView.sectionHeaderTopPadding = .leastNormalMagnitude
        return tableView
    }()
    
    private let profileHeader: ProfileEditTableViewHeader = {
        let header = ProfileEditTableViewHeader()
        header.backgroundColor = .systemBackground
        header.changeProfilePicButton.addTarget(self, action: #selector(didTapChangeProfilePic), for: .touchUpInside)
        return header
    }()
    
    init(userData: User) {
        super.init(nibName: nil, bundle: nil)
        configureModels(with: userData)
        print("Obtained following URL: ---> \(userData.profilePhotoURL)")
        downloadProfilePicture(with: URL(string: userData.profilePhotoURL)!)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        setupConstraints()
        tableView.dataSource = self
        tableView.delegate = self
        profileHeader.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: 180)
        tableView.tableHeaderView = profileHeader
        title = "Edit Profile"
        view.backgroundColor = .systemBackground
        configureNavigationBar()
    }
    
    private func configureModels(with userData: User) {
        //name, username, website, bio
        let section1 = [EditProfileFormModel(label: "Name", placeholder: "Name", value: userData.name, formKind: .name),
                        EditProfileFormModel(label: "Username", placeholder: "Username", value: userData.username, formKind: .username),
                        EditProfileFormModel(label: "Bio", placeholder: "Bio", value: userData.bio, formKind: .bio)]
        models.append(section1)
        
        //private phone, email, gender
        let section2 = [EditProfileFormModel(label: "Phone", placeholder: "Phone", value: userData.phoneNumber, formKind: .phone),
                        EditProfileFormModel(label: "Email", placeholder: "Email", value: userData.emailAdress, formKind: .email),
                        EditProfileFormModel(label: "Gender", placeholder: "Gender", value: userData.gender, formKind: .gender)]
        models.append(section2)
    }
    
//    private func getData() {
//        StorageManager.shared.downloadURL(for: path) { result in
//            switch result {
//            case .success(let url):
//                self.downloadImage(with: url)
//            case .failure(let error):
//                print("Failed to get download url \(error)")
//            }
//        }
//
//    }
    
    private func downloadProfilePicture(with url: URL) {
        DispatchQueue.main.async {
            SDWebImageManager.shared.loadImage(with: url, options: [], progress: nil) { image, data, error, cache, bool, url in
                self.profileHeader.configure(with: image)
            }
        } 
    }
    
    private func configureNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didTapSave))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(didTapCancel))
        
        navigationItem.leftBarButtonItem?.tintColor = .label
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc func didTapSave() {
        self.dismiss(animated: true)
        if hasChangedProfilePic {
            let image = self.profileHeader.getChosenProfilePic()
            DatabaseManager.shared.updateUserProfile(for: AuthenticationManager.currentUserUID!, with: self.changedValues, profilePic: image)
        } else {
            DatabaseManager.shared.updateUserProfile(for: AuthenticationManager.currentUserUID!, with: self.changedValues, profilePic: nil)
        }
        
        
//        StorageManager.shared.uploadUserProfilePhoto(for: currentUserEmail, with: image, fileName: "\(currentUserEmail)_ProfilePicture.png") { result in
//            switch result {
//            case .success(let downloadUrl):
//                UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
//                print(downloadUrl)
//            case .failure(let error):
//                print("Storage manager error: \(error)")
//            }
//        }
    }
    
    @objc func didTapCancel() {
        self.dismiss(animated: true)
    }
    
    @objc func didTapChangeProfilePic() {
        let actionSheet = UIAlertController(title: "Profile Picture", message: "Change profile picture", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { [weak self] _ in
            self?.presentCameraView()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Choose from Library", style: .default, handler: { [weak self] _ in
            self?.presentPhotoLibraryView()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return models.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: FormTableViewCell.identifier, for: indexPath) as! FormTableViewCell
        cell.selectionStyle = .none
        cell.configure(with: model )
        cell.delegate = self
        return cell 
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 1 else {
            return nil
        }
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: EditProfileSectionHeader.identifier) as! EditProfileSectionHeader
        view.title.text = "Private Info"
        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 80
        } else {
            return 0
        }
        
    }
    
}

extension EditProfileViewController: FormTableViewCellDelegate {
    
    
    func formTableViewCell(_ cell: FormTableViewCell, didUpdateModel model: EditProfileFormModel) {
        switch model.formKind {
        case .name:
            changedValues["name"] = model.value
        case .username:
            changedValues["username"] = model.value
        case .bio:
            changedValues["bio"] = model.value
        case .email:
            changedValues["email"] = model.value
        case .phone:
            changedValues["phoneNumber"] = model.value
        case .gender:
            changedValues["gender"] = model.value
        }
    }
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentCameraView() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.cameraCaptureMode = .photo
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    // -- MARK: Not using PHPickerController because it doesnt have editing functionality like ImagePickerController does with .allowsEditing
//    func presentPhotoLibraryView() {
//        var configuration = PHPickerConfiguration(photoLibrary: .shared())
//        configuration.selectionLimit = 1
//        configuration.filter = PHPickerFilter.any(of: [.images, .livePhotos])
//        let picker = PHPickerViewController(configuration: configuration)
//        picker.delegate = self
//        picker.isEditing = true
//        picker.setEditing(true, animated: true)
//        self.present(picker, animated: true)
//    }
    
    private func presentPhotoLibraryView() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.mediaTypes = ["public.image"]
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        self.profileHeader.configure(with: selectedImage)
        self.hasChangedProfilePic = true
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
 
