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

    private let viewModel: LoginViewModel
    var shouldShowOnAppearAnimation: Bool = false
    var hasFinishedLogginIn = Observable(false)

    private var isKeyboardVisible: Bool = false

    private let logoImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "ZoogramGraphicLogo")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let usernameEmailField: CustomTextField = {
        let field = CustomTextField()
        let placeholder = String(localized: "Email")
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = placeholder
        field.keyboardType = .emailAddress
//        I had to change autocorrectionType and textContentType, because of the bug in iOS 17 with isSecureTextEntry fields and autofill bar,
//        which caused the keyboard flickering and views jumping.
        field.autocorrectionType = .no
        field.textContentType = .oneTimeCode
        field.backgroundColor = Colors.backgroundSecondary
        field.returnKeyType = .next
        return field
    }()

    private let passwordField: CustomTextField = {
        let field = CustomTextField()
        let placeholder = String(localized: "Password")
        field.translatesAutoresizingMaskIntoConstraints = false
        field.isSecureTextEntry = true
        field.placeholder = placeholder
        field.returnKeyType = .continue
        field.textContentType = .oneTimeCode
        field.autocorrectionType = .no
        field.backgroundColor = Colors.backgroundSecondary
        return field
    }()

    private lazy var forgottenPasswordButton: UIButton = {
        let button = UIButton()
        let title = String(localized: "Forgot password?")
        button.setTitle(title, for: .normal)
        button.setTitleColor(.systemGray, for: .normal)
        button.titleLabel?.font = CustomFonts.regularFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapForgotPassword), for: .touchUpInside)
        return button
    }()

    private lazy var loginButton: CustomButton = {
        let button = CustomButton()
        let title = String(localized: "Log In")
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(didTapLoginButton), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var createAccountButton: UIButton = {
        let button = UIButton()
        let title = String(localized: "Create an account")
        button.setTitleColor(Colors.label, for: .normal)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = CustomFonts.regularFont(ofSize: 17)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapCreateAccountButton), for: .touchUpInside)
        return button
    }()

    init(service: LoginServiceProtocol) {
        self.viewModel = LoginViewModel(service: service)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        usernameEmailField.delegate = self
        passwordField.delegate = self
        view.backgroundColor = Colors.background
        view.addSubviews(logoImage, usernameEmailField, passwordField, forgottenPasswordButton, loginButton, createAccountButton)
        self.navigationController?.isNavigationBarHidden = true
        setNavigationBarAppearence()
        setupConstraints()
        setupErrorHandler()
        setupEdditingInteruptionGestures()
        setupKeyboardEventsObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if shouldShowOnAppearAnimation {
            hideUIElements(animate: false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldShowOnAppearAnimation {
            self.onAppearAnimation()
            self.shouldShowOnAppearAnimation = false
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    private func setupKeyboardEventsObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
    }

    @objc private func keyboardWillHide() {
        self.isKeyboardVisible = false
    }

    @objc private func keyboardWillShow() {
        self.isKeyboardVisible = true
    }

    func setNavigationBarAppearence() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.titleTextAttributes = [.foregroundColor: Colors.label]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: Colors.label]
        navBarAppearance.backgroundColor = Colors.backgroundSecondary
        navBarAppearance.shadowColor = .clear
        self.navigationController?.navigationBar.standardAppearance = navBarAppearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        self.navigationController?.navigationBar.tintColor = Colors.label
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            logoImage.topAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 75),
            logoImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImage.widthAnchor.constraint(equalToConstant: 85),
            logoImage.heightAnchor.constraint(equalToConstant: 85),

            usernameEmailField.topAnchor.constraint(equalTo: logoImage.bottomAnchor, constant: 70),
            usernameEmailField.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40),
            usernameEmailField.heightAnchor.constraint(equalToConstant: 50),
            usernameEmailField.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            passwordField.topAnchor.constraint(equalTo: usernameEmailField.bottomAnchor, constant: 15),
            passwordField.widthAnchor.constraint(equalTo: usernameEmailField.widthAnchor),
            passwordField.heightAnchor.constraint(equalTo: usernameEmailField.heightAnchor),
            passwordField.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 20),
            loginButton.widthAnchor.constraint(equalTo: usernameEmailField.widthAnchor),
            loginButton.heightAnchor.constraint(equalTo: usernameEmailField.heightAnchor),
            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            forgottenPasswordButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 20),
            forgottenPasswordButton.centerXAnchor.constraint(equalTo: loginButton.centerXAnchor),
            forgottenPasswordButton.heightAnchor.constraint(equalToConstant: 25),

            createAccountButton.topAnchor.constraint(greaterThanOrEqualTo: forgottenPasswordButton.bottomAnchor, constant: 15),
            createAccountButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            createAccountButton.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            createAccountButton.heightAnchor.constraint(equalTo: loginButton.heightAnchor),
            createAccountButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            createAccountButton.bottomAnchor.constraint(lessThanOrEqualTo: view.keyboardLayoutGuide.topAnchor, constant: -15),
        ])
    }
    

    private func onAppearAnimation() {
        self.logoImage.transform = CGAffineTransform(translationX: 0, y: -(self.view.frame.height - self.logoImage.frame.height))
        self.loginButton.transform = CGAffineTransform(translationX: 0, y: 300)
        self.createAccountButton.transform = CGAffineTransform(translationX: 0, y: 300)
        self.forgottenPasswordButton.transform = CGAffineTransform(translationX: 0, y: 300)
        UIView.animate(withDuration: 0.5) {
            self.logoImage.transform = .identity
            self.loginButton.transform = .identity
            self.createAccountButton.transform = .identity
            self.forgottenPasswordButton.transform = .identity
            self.view.alpha = 1
            self.navigationController?.navigationBar.alpha = 1
        }
    }

    @MainActor
    private func showMainScreen() {
        UIView.animate(withDuration: 1.0) {
            self.logoImage.transform = CGAffineTransform(translationX: 0, y: -(self.view.frame.height - self.logoImage.frame.height))
            self.loginButton.transform = CGAffineTransform(translationX: 0, y: 300)
            self.createAccountButton.transform = CGAffineTransform(translationX: 0, y: 300)
            self.forgottenPasswordButton.transform = CGAffineTransform(translationX: 0, y: 300)
            self.view.alpha = 0
        } completion: { _ in
            self.hasFinishedLogginIn.value = true
            self.view.window?.rootViewController = TabBarController(showAppearAnimation: true)
        }
    }

    @objc func didTapLoginButton() {
        guard let usernameEmail = usernameEmailField.text,
              let password = passwordField.text
        else {
            return
        }
        Task {
            await viewModel.loginUser(with: usernameEmail, password: password)
            self.showMainScreen()
        }
    }

    @objc func didTapCreateAccountButton() {
        let service = RegistrationService()
        let registrationVC = RegistrationViewController(service: service)
        registrationVC.shouldKeepKeyboardFromPreviousVC = self.isKeyboardVisible
        navigationController?.pushViewController(registrationVC, animated: true)
    }

    @objc func didTapForgotPassword() {
        guard let email = usernameEmailField.text else {
            return
        }
        Task {
            await viewModel.resetPassword(for: email)
            let notificationText = String(localized: "Please check your email for password reset link and follow the instructions")
            self.displayNotificationToUser(title: "", text: notificationText, prefferedStyle: .alert, action: nil)
        }
    }
}

extension LoginViewController {

    func setupErrorHandler() {
        viewModel.errorHandler = { errorDescription in
            self.showPopUp(issueText: errorDescription)
        }
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
