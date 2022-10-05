//
//  UserInfoForm.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 05.10.2022.
//

import UIKit

class UserInfoForm: UIView {

    private let profilePictureView: ProfilePictureHeader = {
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
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 5, bottom: 10, right: 5)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.returnKeyType = .done
        return textView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubviews(profilePictureView, nameTextField, bioTextView)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            profilePictureView.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            profilePictureView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            profilePictureView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            profilePictureView.heightAnchor.constraint(equalToConstant: 160),
            
            nameTextField.topAnchor.constraint(equalTo: profilePictureView.bottomAnchor, constant: 20),
            nameTextField.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -40),
            nameTextField.heightAnchor.constraint(equalToConstant: 45),
            nameTextField.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            
            bioTextView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 10),
            bioTextView.widthAnchor.constraint(equalTo: nameTextField.widthAnchor),
            bioTextView.heightAnchor.constraint(equalToConstant: 90),
            bioTextView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
        ])
    }

}
