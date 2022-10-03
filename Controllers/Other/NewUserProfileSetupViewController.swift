//
//  NewUserProfileSetupViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 29.01.2022.
//

import UIKit


class NewUserProfileSetupViewController: UIViewController {
    
    let genders = [Gender.male.rawValue, Gender.female.rawValue, Gender.other.rawValue]
    
    let email = UserDefaults.standard.value(forKey: "email") as! String
    let username = UserDefaults.standard.value(forKey: "username") as! String
    
    var imagePicker = UIImagePickerController()
    
    var profileEdditingHeader: ProfileEdittingTableViewHeader = {
        let header = ProfileEdittingTableViewHeader()
        header.backgroundColor = .systemBackground
        header.translatesAutoresizingMaskIntoConstraints = false
        return header
    }()
    
    private let backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorScheme.lightYellowBackground
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
    
    // -- MARK: Below UI elements data is private by default
    private let privacyDescriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.text = "Data entered below is private by default and only visible to you"
        label.numberOfLines = 0
        return label
    }()
    
    private let phoneNumberField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Phone number"
        textField.returnKeyType = .done
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
    
    private let genderField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Gender"
        textField.returnKeyType = .next
        textField.leftViewMode = .always
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.layer.masksToBounds = true
        textField.layer.cornerRadius = 11
        textField.backgroundColor = .systemBackground
        return textField
    }()
    
    private let ageField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Age"
        textField.returnKeyType = .done
        textField.leftViewMode = .always
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.layer.masksToBounds = true
        textField.layer.cornerRadius = 11
        textField.backgroundColor = .systemBackground
        return textField
    }()
    
    private let datePicker: UIDatePicker = {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        genderField.inputView = pickerView
        profileEdditingHeader.delegate = self
        ageField.inputView = datePicker
        pickerView.delegate = self
        pickerView.dataSource = self
        bioTextView.delegate = self
        
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
        setupNavigationBar()
        setupViewsAndConstraint()
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: nil, action: #selector(didTapSave))
    }
    
    
    @objc func didTapSave() {
        let image = self.profileEdditingHeader.getChosenProfilePic()
        guard let userID = AuthenticationManager.currentUserUID else {
            return
        }
        StorageManager.shared.uploadUserProfilePhoto(for: userID, with: image, fileName: "\(self.email)_ProfilePicture.png") { [weak self] result in
            
            switch result {
                
            case .success(let downloadUrl):
                UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                let newuser = ZoogramUser(profilePhotoURL: downloadUrl,
                                   email: self?.email ?? "",
                                   phoneNumber: self?.phoneNumberField.text,
                                   username: self?.username ?? "",
                                   name: self?.nameTextField.text ?? "",
                                   bio: self?.bioTextView.text,
                                   birthday: (self?.ageField.text)!,
                                   gender: (self?.genderField.text)!,
                                   following: 0,
                                   followers: 0,
                                   posts: 0,
                                   joinDate: Date().timeIntervalSince1970)
                DatabaseManager.shared.insertNewUser(with: newuser) { success in
                    if success {
                        print("Succesfully created new user for \(newuser.email) with username: \(newuser.username)")
                        self?.view.window?.rootViewController = TabBarController()
                    } else {
                       print("There was a problem creating your account")
                    }
                }

            case .failure(let error):
                print("Storage manager error: \(error)")
            }
        }
    }
    
    @objc private func showGenderPickerView() {
        let genderPicker = UIPickerView()
        genderPicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(genderPicker)
        genderPicker.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        genderPicker.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        genderPicker.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    @objc private func datePickerValueChanged(_ sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let selectedDate: String = dateFormatter.string(from: sender.date)
        ageField.text = selectedDate
    }
    
    private func setupViewsAndConstraint() {
        view.addSubviews(profileEdditingHeader, backgroundView)
        backgroundView.addSubviews(nameTextField, bioTextView, privacyDescriptionLabel, phoneNumberField, genderField, ageField)
        
        NSLayoutConstraint.activate([
            profileEdditingHeader.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            profileEdditingHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileEdditingHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            profileEdditingHeader.heightAnchor.constraint(equalToConstant: 160),
            
            backgroundView.topAnchor.constraint(equalTo: profileEdditingHeader.bottomAnchor),
            backgroundView.widthAnchor.constraint(equalTo: view.widthAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            nameTextField.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 20),
            nameTextField.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40),
            nameTextField.heightAnchor.constraint(equalToConstant: 45),
            nameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            bioTextView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 10),
            bioTextView.widthAnchor.constraint(equalTo: nameTextField.widthAnchor),
            bioTextView.heightAnchor.constraint(equalToConstant: 90),
            bioTextView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            privacyDescriptionLabel.topAnchor.constraint(equalTo: bioTextView.bottomAnchor, constant: 30),
            privacyDescriptionLabel.leadingAnchor.constraint(equalTo: bioTextView.leadingAnchor, constant: 5),
            privacyDescriptionLabel.trailingAnchor.constraint(equalTo: bioTextView.trailingAnchor),
            privacyDescriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: phoneNumberField.topAnchor),
            
            phoneNumberField.topAnchor.constraint(equalTo: privacyDescriptionLabel.bottomAnchor, constant: 10),
            phoneNumberField.widthAnchor.constraint(equalTo: nameTextField.widthAnchor),
            phoneNumberField.heightAnchor.constraint(equalToConstant: 45),
            phoneNumberField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            genderField.topAnchor.constraint(equalTo: phoneNumberField.bottomAnchor, constant: 10),
            genderField.widthAnchor.constraint(equalTo: phoneNumberField.widthAnchor),
            genderField.heightAnchor.constraint(equalToConstant: 45),
            genderField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            ageField.topAnchor.constraint(equalTo: genderField.bottomAnchor, constant: 10),
            ageField.widthAnchor.constraint(equalTo: genderField.widthAnchor),
            ageField.heightAnchor.constraint(equalToConstant: 45),
            ageField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            
        ])
    }
}



extension NewUserProfileSetupViewController: UITextViewDelegate, UITextFieldDelegate {
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            bioTextView.becomeFirstResponder()
        }
        return true
    }
}

extension NewUserProfileSetupViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    
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
        pickerView.resignFirstResponder()
    }
}

extension NewUserProfileSetupViewController: ProfileEdditingHeaderProtocol {
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.profileEdditingHeader.configure(with: selectedImage)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}


