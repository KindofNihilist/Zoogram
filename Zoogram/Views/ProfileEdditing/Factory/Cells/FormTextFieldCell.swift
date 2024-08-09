//
//  FormTextFieldCell.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.01.2024.
//

import UIKit

class FormTextFieldCell: FormEdditingViewCell {

    var textField: UITextField = {
        let textField = UITextField()
        textField.returnKeyType = .done
        textField.font = CustomFonts.regularFont(ofSize: 14)
        textField.leftViewMode = .always
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        return textField
    }()

    override func configure(with model: EditProfileFormModel) {
        self.model = model
        if model.formKind == .email {
            textField.keyboardType = .emailAddress
        }
        formLabel.text = model.label
        textField.placeholder = model.placeholder
        textField.text = model.value
        textField.addTarget(self, action: #selector(textFieldValueDidChange), for: .editingChanged)
    }

    override func configureRightView() {
        textField.delegate = self
        rightView.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: rightView.topAnchor),
            textField.leadingAnchor.constraint(equalTo: rightView.leadingAnchor),
            textField.bottomAnchor.constraint(equalTo: rightView.bottomAnchor),
            textField.trailingAnchor.constraint(equalTo: rightView.trailingAnchor, constant: -5)
        ])
    }

    @objc func textFieldValueDidChange() {
        model?.value = textField.text
        guard let model = model else {
            return
        }
        delegate?.didUpdateModel(model)
     }
}

extension FormTextFieldCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
