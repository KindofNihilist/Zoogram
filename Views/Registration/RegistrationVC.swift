//
//  emailVC.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 05.10.2022.
//

import UIKit

class RegistrationVC: UIViewController {
    
    var activeViewIndex = 0
    var scrollViewHeight: CGFloat = 225
    var continueButtonYAnchorConstraint: NSLayoutConstraint!
    
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isScrollEnabled = false
        return scrollView
    }()
    
    let emailView: RegistrationForm = {
        let view = RegistrationForm(descriptionText: "Enter your Email", textFieldPlaceholder: "Email")
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 20
        return view
    }()
    
    let usernameView: RegistrationForm = {
        let view = RegistrationForm(descriptionText: "Create a username", textFieldPlaceholder: "Username")
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 20
        return view
    }()
    
    let passwordView: RegistrationForm = {
        let view = RegistrationForm(descriptionText: "Create a password", textFieldPlaceholder: "Password", isPasswordForm: true)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 20
        return view
    }()
    
    let userInfoView: UserInfoForm = {
        let view = UserInfoForm()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 20
        return view
    }()
    
    private let continueButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Continue", for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(moveToNextView), for: .touchUpInside)
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorScheme.lightYellowBackground
        view.addSubviews(scrollView, continueButton)
        scrollView.addSubviews(emailView, usernameView, passwordView)
        setupConstraints()
        setupScrollView()
        navigationItem.backBarButtonItem?.tintColor = .label
        navigationItem.backButtonDisplayMode = .minimal
    }
    
    @objc func moveToNextView() {
        if activeViewIndex < 2 {
            animateContinueButton()
            let views = [emailView, usernameView, passwordView]
            let x = views[activeViewIndex].frame.maxX
            activeViewIndex += 1
    //        scrollView.scrollRectToVisible(views[activeViewIndex].frame, animated: true)
            UIView.animate(withDuration: 0.5) {
                self.scrollView.setContentOffset(CGPoint(x: x , y: 0), animated: false)
            }
        } else {
            showUserInfoForm()
        }
        
        
    }
    
    func animateContinueButton() {
        UIView.animate(withDuration: 0.1) {
            self.continueButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.continueButton.transform = CGAffineTransform.identity
            }
        }

    }
    
    func showUserInfoForm() {
        view.addSubview(userInfoView)
        
        NSLayoutConstraint.activate([
            userInfoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            userInfoView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -50),
            userInfoView.heightAnchor.constraint(equalToConstant: 300),
            userInfoView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        userInfoView.transform = CGAffineTransform(translationX: view.frame.width, y: 0)
//        continueButtonYAnchorConstraint.isActive = false
//
//        continueButtonYAnchorConstraint = continueButton.topAnchor.constraint(equalTo: userInfoView.bottomAnchor, constant: 20)
//        continueButtonYAnchorConstraint.isActive = true

        UIView.animateKeyframes(withDuration: 0.7, delay: 0) {
            //Hide scrollView
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.4) {
                self.scrollView.alpha = 0
                self.scrollView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
            }
            //Move continue button to the bottom and slide in UserInfoView
            UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.6) {
                self.continueButton.transform = CGAffineTransform(translationX: 0, y: 75)
                self.userInfoView.transform = CGAffineTransform.identity
            }
//            self.continueButton.layoutIfNeeded()
        }
    }
    
    func setupScrollView() {
        scrollView.contentSize = CGSize(width: view.frame.width * 3, height: scrollViewHeight)
    }
    
    
    
    func setupConstraints() {
        let continueButtonYAnchorConstraint = continueButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 20)
        NSLayoutConstraint.activate([
            
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            scrollView.widthAnchor.constraint(equalTo: view.widthAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: scrollViewHeight),
            
            emailView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            emailView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -50),
            emailView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            emailView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 25),
            
            usernameView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            usernameView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -50),
            usernameView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            usernameView.leadingAnchor.constraint(equalTo: emailView.trailingAnchor, constant: 25),
            
            passwordView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            passwordView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -50),
            passwordView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            passwordView.leadingAnchor.constraint(equalTo: usernameView.trailingAnchor, constant: 25),
            
            continueButtonYAnchorConstraint,
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            continueButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        self.continueButtonYAnchorConstraint = continueButtonYAnchorConstraint
    }
}
