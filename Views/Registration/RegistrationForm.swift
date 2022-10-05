//
//  RegistrationForm.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 05.10.2022.
//

import UIKit

class RegistrationForm: UIView {

    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .label
        label.textAlignment = .center
        label.font = .rounded(ofSize: 35, weight: .bold)
        label.sizeToFit()
        return label
    }()
    
    private let textField: UITextField = {
        let field = UITextField()
        field.returnKeyType = .next
        field.leftViewMode = .always
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.layer.masksToBounds = true
        field.layer.cornerRadius = 11
        field.backgroundColor = .secondarySystemBackground
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    

    init(descriptionText: String, textFieldPlaceholder: String, isPasswordForm: Bool = false) {
        super.init(frame: CGRect())
        self.descriptionLabel.text = descriptionText
        self.textField.placeholder = textFieldPlaceholder
        self.addSubviews(descriptionLabel, textField)
        if isPasswordForm {
            textField.isSecureTextEntry = true
        }
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 25),
            descriptionLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            descriptionLabel.leadingAnchor.constraint(lessThanOrEqualTo: self.leadingAnchor, constant: 10),
            descriptionLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: 10),
            
            textField.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 30),
            textField.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            textField.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
}
