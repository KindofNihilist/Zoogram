//
//  LoginViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//
//import FirebaseAuth
import UIKit
import SwiftUI

class LoginViewController: UIViewController {
    
    private let headerView: UIView = {
        let header = UIView()
        header.clipsToBounds = true
        header.backgroundColor = ColorScheme.lightYellowBackground
        header.translatesAutoresizingMaskIntoConstraints = false
        return header
    }()
    
    private let logo: UILabel = {
        let label = UILabel()
        label.text = "Zoogram"
        label.textColor = .black
        label.font = UIFont(name: "Noteworthy-Bold", size: 45)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let logoImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "paw")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let usernameEmailField: UITextField = {
        let field = UITextField()
        field.placeholder = "Username or Email"
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
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 11
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(didTapLoginButton), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let createAccountButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(.label, for: .normal)
        button.setTitle("Create an account", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapCreateAccountButton), for: .touchUpInside)
        return button
    }()
    
    private let termsButton: UIButton = {
        let button = UIButton()
        button.setTitle("Terms of Service", for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapTermsButton), for: .touchUpInside)
        return button
    }()
    
    private let privacyButton: UIButton = {
        let button = UIButton()
        button.setTitle("Privacy Policy", for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapPrivacyButton), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameEmailField.delegate = self
        passwordField.delegate = self
        view.backgroundColor = .systemBackground
        view.addSubviews(headerView, usernameEmailField, passwordField, loginButton, createAccountButton, termsButton, privacyButton)
        headerView.addSubviews(logo, logoImage)
        setupConstraints()
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 200),
            
            logo.centerXAnchor.constraint(equalTo: headerView.centerXAnchor, constant: -10),
            logo.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 10),
            logo.widthAnchor.constraint(equalToConstant: 183),
            logo.heightAnchor.constraint(equalToConstant: 75),
            
            logoImage.leadingAnchor.constraint(equalTo: logo.trailingAnchor),
            logoImage.centerYAnchor.constraint(equalTo: logo.centerYAnchor, constant: 4),
            logoImage.heightAnchor.constraint(equalToConstant: 30),
            logoImage.widthAnchor.constraint(equalToConstant: 30),
            
            
            usernameEmailField.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 35),
            usernameEmailField.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40),
            usernameEmailField.heightAnchor.constraint(equalToConstant: 50),
            usernameEmailField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            passwordField.topAnchor.constraint(equalTo: usernameEmailField.bottomAnchor, constant: 15),
            passwordField.widthAnchor.constraint(equalTo: usernameEmailField.widthAnchor),
            passwordField.heightAnchor.constraint(equalTo: usernameEmailField.heightAnchor),
            passwordField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 20),
            loginButton.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            createAccountButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 10),
            createAccountButton.widthAnchor.constraint(equalTo: loginButton.widthAnchor),
            createAccountButton.heightAnchor.constraint(equalTo: loginButton.heightAnchor),
            createAccountButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            privacyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            privacyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            privacyButton.heightAnchor.constraint(equalToConstant: 20),
            privacyButton.widthAnchor.constraint(equalToConstant: 150),
            
            termsButton.bottomAnchor.constraint(equalTo: privacyButton.topAnchor, constant: -20),
            termsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            termsButton.heightAnchor.constraint(equalToConstant: 20),
            termsButton.widthAnchor.constraint(equalToConstant: 150),
        ])
    }
    
    
    @objc func didTapLoginButton() {
        passwordField.resignFirstResponder()
        usernameEmailField.resignFirstResponder()
        
        guard let usernameEmail = usernameEmailField.text, !usernameEmail.isEmpty, let password = passwordField.text, !password.isEmpty, password.count >= 8
        else {
            var alertMessage = ""
            if let username = usernameEmailField.text, let password = passwordField.text {
                if username.isEmpty && password.isEmpty {
                    alertMessage = "Username and password fields cannot be empty"
                } else if username.isEmpty {
                    alertMessage = "You need to enter your username or email"
                } else if password.isEmpty {
                    alertMessage = "You need to enter your account password"
                }
            }
            showAlert(with: alertMessage)
            return
        }
        
        var username: String?
        var email: String?
        
        if usernameEmail.contains("@"), usernameEmail.contains(".") {
            email = usernameEmail
        } else {
            username = usernameEmail
        }
        
        AuthenticationManager.shared.loginUser(username: username, email: email, password: password) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let userData):
                    self.view.window?.rootViewController = TabBarController(userData: userData)
                    print("succesfullyLoggedIn")
                    UserDefaults.standard.set(email, forKey: "email")
                    UserDefaults.standard.set(username, forKey: "username")
                case .failure(let error):
                    print(error)
                    let message = "Could not log you in"
                    self.showAlert(with: message)
                }
            }
        }
    }
    
    private func showAlert(with message: String) {
        let alert = UIAlertController(title: "Log in error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
        self.present(alert, animated: true)
    }
    
    @objc func didTapCreateAccountButton() {
        let vc = UINavigationController(rootViewController: RegistrationViewController())
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    @objc func didTapTermsButton() {
        
    }
    
    @objc func didTapPrivacyButton() {
        
    }
    
    
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameEmailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            didTapLoginButton()
        }
        return true
    }
}
