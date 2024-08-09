//
//  FormGenderPickerCell.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.01.2024.
//

import UIKit

class FormGenderPickerCell: FormEdditingViewCell {

    var genderPicker: GenderPicker = {
        let picker = GenderPicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()

    override func configure(with model: EditProfileFormModel) {
        super.configure(with: model)
        genderPicker.text = model.value

        genderPicker.didSelectAction = { gender in
            if var unwrappedModel = self.model {
                unwrappedModel.value = gender.localizedString()
                self.delegate?.didUpdateModel(unwrappedModel)
            }
        }
    }

    override func configureRightView() {
        rightView.addSubview(genderPicker)
        NSLayoutConstraint.activate([
            genderPicker.topAnchor.constraint(equalTo: rightView.topAnchor),
            genderPicker.leadingAnchor.constraint(equalTo: rightView.leadingAnchor, constant: 5),
            genderPicker.bottomAnchor.constraint(equalTo: rightView.bottomAnchor),
            genderPicker.trailingAnchor.constraint(equalTo: rightView.trailingAnchor)
        ])
    }
}
