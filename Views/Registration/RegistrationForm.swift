//
//  RegistrationForm.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 05.10.2022.
//

import UIKit

protocol TextFieldResponder {
    func becomeResponder()
    func resignResponder()
}

class RegistrationForm: UIView {

    var textFieldKeyboardType: UIKeyboardType = .default {
        didSet {
            self.textField.keyboardType = textFieldKeyboardType
        }
    }

    weak var delegate: UITextFieldDelegate? {
        didSet {
            textField.delegate = self.delegate
        }
    }

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Colors.label
        label.textAlignment = .center
        label.font = CustomFonts.boldFont(ofSize: 30)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.sizeToFit()
        return label
    }()

    private let textField: CustomTextField = {
        let field = CustomTextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.returnKeyType = .next
        field.backgroundColor = Colors.backgroundTertiary
        return field
    }()

    private let errorNotificationView: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .systemRed
        label.font = CustomFonts.boldFont(ofSize: 14)
        label.numberOfLines = 0
        label.sizeToFit()
        return label
    }()

    init(descriptionText: String, textFieldPlaceholder: String, isPasswordForm: Bool = false) {
        super.init(frame: CGRect())
        self.descriptionLabel.text = descriptionText
        self.textField.placeholder = textFieldPlaceholder
        self.addSubviews(descriptionLabel, textField, errorNotificationView)
        if isPasswordForm {
            textField.isSecureTextEntry = true
        }
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 25),
            descriptionLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            descriptionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor, constant: 15),
            descriptionLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -15),

            textField.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 45),
            textField.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            textField.heightAnchor.constraint(equalToConstant: 50),

            errorNotificationView.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 15),
            errorNotificationView.leadingAnchor.constraint(equalTo: textField.leadingAnchor, constant: 10),
            errorNotificationView.trailingAnchor.constraint(equalTo: textField.trailingAnchor, constant: -10),
            errorNotificationView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -15)
        ])
    }

    func getTextFieldData() -> String {
        return textField.text!
    }

    @MainActor
    func removeErrorNotification() {
        errorNotificationView.text?.removeAll()
        UIView.animate(withDuration: 0.5) {
            self.superview?.layoutIfNeeded()
        }
    }

    @MainActor
    func showErrorNotification(error: String) {
        errorNotificationView.text = error
        errorNotificationView.shakeByX(offset: 5.0, repeatCount: 2, durationOfOneCycle: 0.07)
        UIView.animate(withDuration: 0.5) {
            self.superview?.layoutIfNeeded()
        }
    }
}

extension RegistrationForm: TextFieldResponder {
    func becomeResponder() {
        self.textField.becomeFirstResponder()
    }

    func resignResponder() {
        self.textField.resignFirstResponder()
    }
}
