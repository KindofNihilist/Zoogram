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

    let viewModel = LoginViewModel()

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

    private let forgottenPasswordButton: UIButton = {
        let button = UIButton()
        button.setTitle("Forgot password?", for: .normal)
        button.setTitleColor(.systemGray, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.sizeToFit()
        return button
    }()

    private lazy var loginButton: CustomButton = {
        let button = CustomButton()
        button.setTitle("Log In", for: .normal)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 11
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(didTapLoginButton), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var createAccountButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(.label, for: .normal)
        button.setTitle("Create an account", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapCreateAccountButton), for: .touchUpInside)
        return button
    }()

    private lazy var termsButton: UIButton = {
        let button = UIButton()
        button.setTitle("Terms of Service", for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapTermsButton), for: .touchUpInside)
        return button
    }()

    private lazy var privacyButton: UIButton = {
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
        view.addSubviews(headerView, usernameEmailField, passwordField, forgottenPasswordButton, loginButton, createAccountButton, termsButton, privacyButton)
        headerView.addSubviews(logo, logoImage)
        setNavigationBarAppearence()
        setupConstraints()
    }

    func setNavigationBarAppearence() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        navBarAppearance.backgroundColor = ColorScheme.lightYellowBackground
        navBarAppearance.shadowColor = .clear
        self.navigationController?.navigationBar.standardAppearance = navBarAppearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        self.navigationController?.navigationBar.tintColor = .label
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

            forgottenPasswordButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 5),
            forgottenPasswordButton.trailingAnchor.constraint(equalTo: passwordField.trailingAnchor),

            loginButton.topAnchor.constraint(equalTo: forgottenPasswordButton.bottomAnchor, constant: 20),
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

            termsButton.bottomAnchor.constraint(equalTo: privacyButton.topAnchor, constant: -15),
            termsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            termsButton.heightAnchor.constraint(equalToConstant: 20),
            termsButton.widthAnchor.constraint(equalToConstant: 150)
        ])
    }

    @objc func didTapLoginButton() {
        passwordField.resignFirstResponder()
        usernameEmailField.resignFirstResponder()

        guard let usernameEmail = usernameEmailField.text, !usernameEmail.isEmpty, let password = passwordField.text, !password.isEmpty, password.count >= 8 else {

            return
        }

        viewModel.loginUser(with: usernameEmail, password: password) { [weak self] isSuccessfull, description in

            switch isSuccessfull {

            case true: self?.view.window?.rootViewController = TabBarController()

            case false: self?.showAlert(with: description)

            }
        }

    }

    private func showAlert(with message: String) {
        let alert = UIAlertController(title: "Could not log you in", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Try again", style: .cancel))
        alert.view.backgroundColor = .secondarySystemBackground
        alert.view.layer.cornerRadius = 10
        self.present(alert, animated: true)
    }

    @objc func didTapCreateAccountButton() {
        let registrationVC = RegistrationVC()
        navigationController?.pushViewController(registrationVC, animated: true)
//        let vc = UINavigationController(rootViewController: RegistrationViewController())
//        vc.modalPresentationStyle = .fullScreen
//        present(vc, animated: true)
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
