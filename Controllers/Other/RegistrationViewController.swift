//
//  RegistrationViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//

import UIKit

class RegistrationViewController: UIViewController {
    
    private let headerView: UIView = {
        let header = UIView()
        header.clipsToBounds = true
        header.backgroundColor = .systemYellow
        header.translatesAutoresizingMaskIntoConstraints = false
        return header
    }()
    
    private let headerLabel: UILabel = {
       let label = UILabel()
        label.text = "Create new account"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let usernameField: UITextField = {
        let field = UITextField()
        field.placeholder = "Username"
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
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.placeholder = "Email"
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
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.isSecureTextEntry = true
        field.placeholder = "Password"
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
    
    private let confirmPasswordField: UITextField = {
        let field = UITextField()
        field.isSecureTextEntry = true
        field.placeholder = "Confirm password"
        field.returnKeyType = .continue
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
    
    private let SignInButton: UIButton = {
        let button = UIButton()
        button.setTitle("Sign In", for: .normal)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 11
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(didTapSignInButton), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        title = "Create new account"
        usernameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        confirmPasswordField.delegate = self
        view.backgroundColor = .systemBackground
        view.addSubviews(usernameField, emailField, passwordField, confirmPasswordField, SignInButton)
//        headerView.addSubview(headerLabel)
        setupNavigationBar()
        setupConstraints()
        
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
//            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            headerView.heightAnchor.constraint(equalToConstant: 70),
//
//            headerLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
//            headerLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
//            headerLabel.heightAnchor.constraint(equalToConstant: 50),
//            headerLabel.widthAnchor.constraint(equalTo: headerView.widthAnchor, constant: -20),
            
            usernameField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 35),
            usernameField.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40),
            usernameField.heightAnchor.constraint(equalToConstant: 50),
            usernameField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            emailField.topAnchor.constraint(equalTo: usernameField.bottomAnchor, constant: 15),
            emailField.widthAnchor.constraint(equalTo: usernameField.widthAnchor),
            emailField.heightAnchor.constraint(equalTo: usernameField.heightAnchor),
            emailField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 15),
            passwordField.widthAnchor.constraint(equalTo: emailField.widthAnchor),
            passwordField.heightAnchor.constraint(equalTo: emailField.heightAnchor),
            passwordField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            confirmPasswordField.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 15),
            confirmPasswordField.widthAnchor.constraint(equalTo: passwordField.widthAnchor),
            confirmPasswordField.heightAnchor.constraint(equalTo: passwordField.heightAnchor),
            confirmPasswordField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            SignInButton.topAnchor.constraint(equalTo: confirmPasswordField.bottomAnchor, constant: 20),
            SignInButton.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40),
            SignInButton.heightAnchor.constraint(equalToConstant: 50),
            SignInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelRegistration))
    }
    
    @objc func cancelRegistration() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapSignInButton() {
        usernameField.resignFirstResponder()
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        confirmPasswordField.resignFirstResponder()
        
        guard let username = usernameField.text, !username.isEmpty,
              let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty,
              let confirmedPass = confirmPasswordField.text, !confirmedPass.isEmpty else {
                  return
              }
        AuthenticationManager.shared.registerNewUser(username: username, email: email, password: password) { registered, message in
            DispatchQueue.main.async {
                if registered {
                    print(message)
                    UserDefaults.standard.set(email, forKey: "email")
                    UserDefaults.standard.set(username, forKey: "username")
                    let vc = NewUserProfileSetupViewController()
                    self.navigationController?.setViewControllers([vc], animated: true)
                } else {
                    print(message)
                }
            }
        }
    }
}

extension RegistrationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            emailField.becomeFirstResponder()
        } else if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            confirmPasswordField.becomeFirstResponder()
        } else {
            didTapSignInButton()
        }
        return true
    }
}
