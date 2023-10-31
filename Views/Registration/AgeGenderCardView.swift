//
//  AgeGenderCardView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.10.2022.
//

import UIKit

class AgeGenderCardView: UIView {

    let genders = [Gender.male.rawValue, Gender.female.rawValue, Gender.other.rawValue]

    private let genderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Gender"
        label.textColor = .label
        label.textAlignment = .center
        label.font = CustomFonts.boldFont(ofSize: 23)
        label.sizeToFit()
        return label
    }()

    private let genderField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textAlignment = .center
        textField.placeholder = "Tap to choose gender"
        textField.returnKeyType = .next
        textField.textColor = .label
        textField.font = .systemFont(ofSize: 18)
        return textField
    }()

    private let ageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Date of birth"
        label.textAlignment = .center
        label.textColor = .label
        label.font = CustomFonts.boldFont(ofSize: 23)
        label.sizeToFit()
        return label
    }()

    private let ageField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textAlignment = .center
        textField.placeholder = "Tap to choose date"
        textField.returnKeyType = .done
        textField.textColor = .label
        textField.font = CustomFonts.regularFont(ofSize: 18)
        return textField
    }()

    private lazy var datePicker: UIDatePicker = {
        let calendar = Calendar.init(identifier: .gregorian)
        var dateComponents = DateComponents()
        dateComponents.year = -100

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .inline
        datePicker.backgroundColor = .systemBackground
        datePicker.maximumDate = Date()
        datePicker.minimumDate = calendar.date(byAdding: dateComponents, to: Date())
        datePicker.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
        return datePicker
    }()

    private let pickerView: UIPickerView = {
        let picker = UIPickerView()
        return picker
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubviews(genderLabel, genderField, ageLabel, ageField)
        setupConstraints()

        genderField.inputView = pickerView
        ageField.inputView = datePicker

        setupDelegates()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            genderLabel.bottomAnchor.constraint(equalTo: genderField.topAnchor, constant: -20),
            genderLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),

            genderField.bottomAnchor.constraint(equalTo: self.centerYAnchor, constant: -30),
            genderField.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -100),
            genderField.heightAnchor.constraint(equalToConstant: 45),
            genderField.centerXAnchor.constraint(equalTo: self.centerXAnchor),

            ageLabel.topAnchor.constraint(equalTo: self.centerYAnchor, constant: 30),
            ageLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),

            ageField.topAnchor.constraint(equalTo: ageLabel.bottomAnchor, constant: 20),
            ageField.widthAnchor.constraint(equalTo: genderField.widthAnchor),
            ageField.heightAnchor.constraint(equalToConstant: 45),
            ageField.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        ])
    }

    func setupDelegates() {
        pickerView.delegate = self
        pickerView.dataSource = self
    }

    @objc private func showGenderPickerView() {
        let genderPicker = UIPickerView()
        genderPicker.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(genderPicker)
        genderPicker.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        genderPicker.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        genderPicker.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }

    @objc private func datePickerValueChanged(_ sender: UIDatePicker) {
        let date = sender.date.formatted(date: .numeric, time: .omitted)
        ageField.text = date
    }

    func getGender() -> String {
        return genderField.text ?? ""
    }

    func getDateOfBirth() -> String {
        return ageField.text ?? ""
    }
}

extension AgeGenderCardView: UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 3
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return genders[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        genderField.text = genders[row]
        self.endEditing(true)
        pickerView.resignFirstResponder()
    }
}
