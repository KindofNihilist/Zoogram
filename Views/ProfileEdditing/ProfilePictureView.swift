//
//  ProfileEditTableViewHeader.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 19.01.2022.
//

import UIKit

@MainActor
protocol ProfilePictureViewDelegate: AnyObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var imagePicker: UIImagePickerController { get set }
    func didTapChangeProfilePic()
    func presentCameraView()
    func presentPhotoLibraryView()
}

class ProfilePictureView: UIView {

    weak var delegate: ProfilePictureViewDelegate?

    private let imageWidthHeight: CGFloat = 115

    private let imageView: ProfilePictureImageView = {
       let imageView = ProfilePictureImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    lazy var changeProfilePicButton: UIButton = {
        let button = UIButton()
        let title = String(localized: "Choose profile photo")
        button.setTitle(title, for: .normal)
        button.setTitleColor(.link, for: .normal)
        button.titleLabel?.font = CustomFonts.boldFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(changeProfilePic), for: .touchUpInside)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubviews(imageView, changeProfilePicButton)
        setupSubviews(for: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = imageView.frame.height / 2
    }

    @objc func changeProfilePic() {
        print("Did tap change profile pic")
        delegate?.didTapChangeProfilePic()
    }

    public func configure(with image: UIImage) {
        imageView.image = image
    }

    public func getChosenProfilePic() -> UIImage {
        return imageView.image!
    }

    private func setupSubviews(for frame: CGRect) {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            imageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.75),
            imageView.widthAnchor.constraint(equalTo: heightAnchor, multiplier: 0.75),

            changeProfilePicButton.topAnchor.constraint(greaterThanOrEqualTo: imageView.bottomAnchor, constant: 20),
            changeProfilePicButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            changeProfilePicButton.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -20),
            changeProfilePicButton.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
}

extension ProfilePictureViewDelegate where Self: UIViewController {

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
       let alertTitle = String(localized: "Profile Picture")
       let alertMessage = String(localized: "Change profile picture")
       let alertActionOneTitle = String(localized: "Take Photo")
       let alertActionTwoTitle = String(localized: "Choose from Library")
       let alertCancelTitle = String(localized: "Cancel")
        let actionSheet = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: alertActionOneTitle, style: .default, handler: { [weak self] _ in
            self?.presentCameraView()
        }))

        actionSheet.addAction(UIAlertAction(title: alertActionTwoTitle, style: .default, handler: { [weak self] _ in
            self?.presentPhotoLibraryView()
        }))

        actionSheet.addAction(UIAlertAction(title: alertCancelTitle, style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
