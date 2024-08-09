//
//  GenderPicker.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.01.2024.
//

import UIKit

class GenderPicker: UILabel {

    var didSelectAction: ((Gender) -> Void)?

    private let genders = [Gender.male, Gender.female, Gender.other]

    private lazy var dummyGenderPickerTextField: UITextField = {
        let textField = UITextField(frame: .zero)
        textField.inputView = self.genderPickerView
        return textField
    }()

    private let genderPickerView: UIPickerView = {
        let picker = UIPickerView()
        return picker
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(dummyGenderPickerTextField)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapToSelectGender))
        self.addGestureRecognizer(tapGestureRecognizer)
        self.font = CustomFonts.regularFont(ofSize: 14)
        self.isUserInteractionEnabled = true
        genderPickerView.delegate = self
        genderPickerView.dataSource = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTapToSelectGender() {
        dummyGenderPickerTextField.becomeFirstResponder()
    }
}

extension GenderPicker: UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 3
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.textAlignment = .center
        label.text = genders[row].localizedString()
        label.font = CustomFonts.regularFont(ofSize: 20)
        label.isUserInteractionEnabled = true
        return label
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedGender = genders[row]
        self.text = selectedGender.localizedString()
        self.textColor = Colors.label
        self.endEditing(true)
        didSelectAction?(selectedGender)
        pickerView.resignFirstResponder()
    }
}
