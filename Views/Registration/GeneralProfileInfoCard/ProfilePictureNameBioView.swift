//
//  ProfileGeneralCardView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.10.2022.
//

import UIKit

class ProfilePictureNameBioView: UIView {

    private let bioPlaceholderText = String(localized: "Bio")

    weak var delegate: UITextFieldDelegate? {
        didSet {
            self.nameTextField.delegate = self.delegate
        }
    }

    var profilePictureHeaderView: ProfilePictureView = {
        let view = ProfilePictureView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let nameTextField: CustomTextField = {
        let textField = CustomTextField()
        let placeholder = String(localized: "Name")
        textField.backgroundColor = Colors.backgroundTertiary
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = placeholder
        textField.returnKeyType = .next
        return textField
    }()

    private lazy var bioTextView: UITextView = {
        let textView = UITextView()
        textView.text = bioPlaceholderText
        textView.textColor = .placeholderText
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .yes
        textView.layer.masksToBounds = true
        textView.layer.cornerRadius = 13
        textView.font = CustomFonts.regularFont(ofSize: 17)
        textView.backgroundColor = Colors.backgroundTertiary
        textView.textContainerInset = UIEdgeInsets(top: 5, left: 5, bottom: 0, right: 5)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.returnKeyType = .done
        return textView
    }()

    init(profilePictureHeaderDelegate: ProfilePictureViewDelegate) {
        self.profilePictureHeaderView.delegate = profilePictureHeaderDelegate
        super.init(frame: CGRect.zero)
        bioTextView.delegate = self
        self.addSubviews(profilePictureHeaderView, nameTextField, bioTextView)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            profilePictureHeaderView.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            profilePictureHeaderView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            profilePictureHeaderView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            profilePictureHeaderView.heightAnchor.constraint(lessThanOrEqualToConstant: 160),

            nameTextField.topAnchor.constraint(equalTo: profilePictureHeaderView.bottomAnchor, constant: 30),
            nameTextField.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -30),
            nameTextField.heightAnchor.constraint(equalToConstant: 45),
            nameTextField.centerXAnchor.constraint(equalTo: self.centerXAnchor),

            bioTextView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 15),
            bioTextView.widthAnchor.constraint(equalTo: nameTextField.widthAnchor),
            bioTextView.heightAnchor.constraint(equalToConstant: 90),
            bioTextView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            bioTextView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -15)
        ])
    }

    func updateProfileHeaderPicture(with image: UIImage) {
        profilePictureHeaderView.configure(with: image)
    }

    func getName() -> String? {
        return nameTextField.text
    }

    func getBio() -> String? {
        if bioTextView.text == bioPlaceholderText {
            return nil
        } else {
            return bioTextView.text
        }
    }

    func getProfilePicture() -> UIImage {
        return profilePictureHeaderView.getChosenProfilePic()
    }

    func showNameFieldIsEmptyError() {
        UIView.animateKeyframes(withDuration: 0.7, delay: 0) {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.6) {
                self.nameTextField.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.4) {
                self.nameTextField.backgroundColor = Colors.backgroundTertiary
            }
        }
        self.nameTextField.shakeByX(offset: 4.0, repeatCount: 2, durationOfOneCycle: 0.07)
    }

    func removeEmptyError() {
        UIView.animate(withDuration: 0.2) {
            self.nameTextField.backgroundColor = .secondarySystemBackground
        }
    }
}

extension ProfilePictureNameBioView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = nil
            textView.textColor = Colors.label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = bioPlaceholderText
            textView.textColor = .placeholderText
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        return numberOfChars < 150
    }
}

extension ProfilePictureNameBioView: TextFieldResponder {

    func becomeResponder() {
        self.nameTextField.becomeFirstResponder()
    }

    func resignResponder() {
        self.nameTextField.resignFirstResponder()
        self.bioTextView.resignFirstResponder()
    }
}
