//
//  ProfileGeneralCardView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.10.2022.
//

import UIKit

class GeneralProfileInfoCardView: UIView {

    var profilePictureHeaderView: ProfilePictureHeader = {
        let view = ProfilePictureHeader()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Name"
        textField.returnKeyType = .next
        textField.leftViewMode = .always
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.layer.masksToBounds = true
        textField.layer.cornerRadius = 11
        textField.backgroundColor = .systemBackground
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private let bioTextView: UITextView = {
        let textView = UITextView()
        textView.text = "Bio"
        textView.textColor = .placeholderText
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .yes
        textView.layer.masksToBounds = true
        textView.layer.cornerRadius = 11
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.backgroundColor = .systemBackground
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.returnKeyType = .done
        //        textView.isScrollEnabled = false
        return textView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubviews(profilePictureHeaderView, nameTextField, bioTextView)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            profilePictureHeaderView.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            profilePictureHeaderView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            profilePictureHeaderView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            profilePictureHeaderView.heightAnchor.constraint(equalToConstant: 160),

            nameTextField.topAnchor.constraint(equalTo: profilePictureHeaderView.bottomAnchor, constant: 15),
            nameTextField.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -30),
            nameTextField.heightAnchor.constraint(equalToConstant: 45),
            nameTextField.centerXAnchor.constraint(equalTo: self.centerXAnchor),

            bioTextView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 10),
            bioTextView.widthAnchor.constraint(equalTo: nameTextField.widthAnchor),
            bioTextView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            bioTextView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10)
        ])
    }

    func setupDelegates(viewController: UIViewController) {
        profilePictureHeaderView.delegate = viewController as? any ProfilePictureHeaderProtocol
        bioTextView.delegate = self
    }

    func updateProfileHeaderPicture(with image: UIImage) {
        profilePictureHeaderView.configure(with: image)
    }

    func getName() -> String {
        return nameTextField.text ?? " "
    }

    func getBio() -> String {
        return bioTextView.text
    }

    func getProfilePicture() -> UIImage {
        return profilePictureHeaderView.getChosenProfilePic()
    }
}

extension GeneralProfileInfoCardView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = nil
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Bio"
            textView.textColor = .placeholderText
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        return numberOfChars < 150
    }
}
