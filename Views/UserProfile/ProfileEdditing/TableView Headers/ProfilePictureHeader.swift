//
//  ProfileEditTableViewHeader.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 19.01.2022.
//

import UIKit

protocol ProfilePictureHeaderProtocol: AnyObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var imagePicker: UIImagePickerController { get set }
    func didTapChangeProfilePic()
    func presentCameraView()
    func presentPhotoLibraryView()
}

class ProfilePictureHeader: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubviews(imageView, changeProfilePicButton)
        setupSubviews()
    }


    weak var delegate: ProfilePictureHeaderProtocol?

    private let imageWidthHeight: CGFloat = 115

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let imageView: UIImageView = {
       let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "person.crop.circle.fill")
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = .systemGray5
        return imageView
    }()

    lazy var changeProfilePicButton: UIButton = {
        let button = UIButton()
        button.setTitle("Choose profile photo", for: .normal)
        button.setTitleColor(.link, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(changeProfilePic), for: .touchUpInside)
        return button
    }()

    @objc func changeProfilePic() {
        print("Change profile pic tapped")
        delegate?.didTapChangeProfilePic()
    }

    public func configure(with image: UIImage) {
        imageView.image = image
    }

    public func getChosenProfilePic() -> UIImage {
        return imageView.image!
    }

    private func setupSubviews() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: imageWidthHeight),
            imageView.heightAnchor.constraint(equalToConstant: imageWidthHeight),

            changeProfilePicButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 15),
            changeProfilePicButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            changeProfilePicButton.heightAnchor.constraint(equalToConstant: 20),
            changeProfilePicButton.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -20)
        ])
        imageView.layer.cornerRadius = imageWidthHeight / 2
    }
}

extension ProfilePictureHeaderProtocol where Self: UIViewController {

    func presentCameraView() {
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.cameraCaptureMode = .photo
        imagePicker.allowsEditing = true
        imagePicker.modalPresentationStyle = .fullScreen
        self.present(imagePicker, animated: true)
    }
    func presentPhotoLibraryView() {
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.mediaTypes = ["public.image"]
        imagePicker.allowsEditing = true
        imagePicker.modalPresentationStyle = .fullScreen
        self.present(imagePicker, animated: true)
    }

   func didTapChangeProfilePic() {
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

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
