//
//  AgeGenderCardView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 11.10.2022.
//

import UIKit

class AgeGenderCardView: UIView {

    private let genders = [Gender.male.localizedString(), Gender.female.localizedString(), Gender.other.localizedString()]
    private let genderPickerPlaceholderText = String(localized: "Tap to choose gender")
    private let datePickerPlaceholderText = String(localized: "Tap to choose date")

    private let genderLabel: UILabel = {
        let label = UILabel()
        let labelText = String(localized: "Gender")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = labelText
        label.textColor = Colors.label
        label.textAlignment = .center
        label.font = CustomFonts.boldFont(ofSize: 23)
        label.sizeToFit()
        return label
    }()

    private lazy var selectedGenderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = genderPickerPlaceholderText
        label.textColor = .placeholderText
        label.font = CustomFonts.regularFont(ofSize: 18)
        label.isUserInteractionEnabled = true

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapToSelectGender))
        label.addGestureRecognizer(tapGestureRecognizer)
        return label
    }()

    private let genderPickerView: UIPickerView = {
        let picker = UIPickerView()
        return picker
    }()

    private lazy var dummyGenderPickerTextField: UITextField = {
        let textField = UITextField(frame: .zero)
        textField.inputView = self.genderPickerView
        return textField
    }()

    private let dateOfBirthLabel: UILabel = {
        let label = UILabel()
        let labelText = String(localized: "Date of birth")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = labelText
        label.textAlignment = .center
        label.textColor = Colors.label
        label.font = CustomFonts.boldFont(ofSize: 23)
        label.sizeToFit()
        return label
    }()

    private lazy var selectedDateOfBirthLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = datePickerPlaceholderText
        label.textColor = .placeholderText
        label.font = CustomFonts.regularFont(ofSize: 18)
        label.isUserInteractionEnabled = true

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapToSelectDateOfBirth))
        label.addGestureRecognizer(tapGestureRecognizer)
        return label
    }()

    private lazy var dummyDatePickerTextField: UITextField = {
        let textField = UITextField(frame: .zero)
        textField.inputView = self.datePicker
        return textField
    }()

    private lazy var datePicker: UIDatePicker = {
        let calendar = Calendar.init(identifier: .gregorian)
        var dateComponents = DateComponents()
        dateComponents.year = -100

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .inline
        datePicker.backgroundColor = Colors.background
        datePicker.maximumDate = Date()
        datePicker.minimumDate = calendar.date(byAdding: dateComponents, to: Date())
        datePicker.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
        return datePicker
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubviews(genderLabel, selectedGenderLabel, dateOfBirthLabel, selectedDateOfBirthLabel, dummyDatePickerTextField, dummyGenderPickerTextField)
        setupConstraints()
        genderPickerView.delegate = self
        genderPickerView.dataSource = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            genderLabel.bottomAnchor.constraint(equalTo: selectedGenderLabel.topAnchor, constant: -20),
            genderLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),

            selectedGenderLabel.bottomAnchor.constraint(equalTo: self.centerYAnchor, constant: -30),
            selectedGenderLabel.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -70),
            selectedGenderLabel.heightAnchor.constraint(equalToConstant: 45),
            selectedGenderLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),

            dateOfBirthLabel.topAnchor.constraint(equalTo: self.centerYAnchor, constant: 30),
            dateOfBirthLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),

            selectedDateOfBirthLabel.topAnchor.constraint(equalTo: dateOfBirthLabel.bottomAnchor, constant: 20),
            selectedDateOfBirthLabel.widthAnchor.constraint(equalTo: selectedGenderLabel.widthAnchor),
            selectedDateOfBirthLabel.heightAnchor.constraint(equalToConstant: 45),
            selectedDateOfBirthLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        ])
    }

    @objc private func datePickerValueChanged(_ sender: UIDatePicker) {
        let date = sender.date.formatted(date: .numeric, time: .omitted)
        selectedDateOfBirthLabel.text = date
        selectedDateOfBirthLabel.textColor = Colors.label
    }

    @objc private func didTapToSelectGender() {
        dummyGenderPickerTextField.becomeFirstResponder()
    }

    @objc private func didTapToSelectDateOfBirth() {
        dummyDatePickerTextField.becomeFirstResponder()
    }

    @objc private func didTapGenderLabel() {
        print("Did tap gender option")
//        genderField.text = sender.text
    }

    func showGenderNotSelectedError() {
        UIView.animate(withDuration: 0.3) {
            self.genderLabel.textColor = .systemRed
        }
        self.genderLabel.shakeByX(offset: 5.0, repeatCount: 2, durationOfOneCycle: 0.07)
    }

    func showDateOfBirthNotSelectedError() {
        UIView.animate(withDuration: 0.3) {
            self.dateOfBirthLabel.textColor = .systemRed
        }
        self.dateOfBirthLabel.shakeByX(offset: 5.0, repeatCount: 2, durationOfOneCycle: 0.07)
    }

    func removeErrorState() {
        UIView.animate(withDuration: 0.2) {
            self.dateOfBirthLabel.textColor = Colors.label
            self.genderLabel.textColor = Colors.label
        }
    }

    func getGender() -> String? {
        guard selectedGenderLabel.text != genderPickerPlaceholderText else {
            return nil
        }
        return selectedGenderLabel.text
    }

    func getDateOfBirth() -> String? {
        guard selectedDateOfBirthLabel.text != datePickerPlaceholderText else {
            return nil
        }
        return selectedDateOfBirthLabel.text
    }
}

extension AgeGenderCardView: UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 3
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.textAlignment = .center
        label.text = genders[row]
        label.font = CustomFonts.regularFont(ofSize: 20)
        label.isUserInteractionEnabled = true

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapGenderLabel))
        label.addGestureRecognizer(tapGestureRecognizer)
        return label
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedGenderLabel.text = genders[row]
        selectedGenderLabel.textColor = Colors.label
        self.endEditing(true)
        pickerView.resignFirstResponder()
    }
}
