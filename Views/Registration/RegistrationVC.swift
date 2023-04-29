//
//  emailVC.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 05.10.2022.
//

import UIKit

class RegistrationVC: UIViewController {
    
    var activeViewIndex = 1 {
        didSet {
            print(activeViewIndex)
        }
    }
    
    var scrollViewHeight: CGFloat = 225
    var continueButtonYAnchorConstraint: NSLayoutConstraint!
    
    let viewModel = RegistrationViewModel()
    
    var imagePicker = UIImagePickerController()
    
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
    
    let generalProfileInfoCardView: GeneralProfileInfoCardView = {
        let view = GeneralProfileInfoCardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 20
        return view
    }()
    
    let ageAndGenderView: AgeGenderCardView = {
        let view = AgeGenderCardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 20
        view.isHidden = true
        return view
    }()
    
    //Since UIView.transition flips parent view of a passed view I needed a container view
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var checkMark: UIImageView = {
        let checkMark = UIImageView(image: .init(systemName: "checkmark.circle.fill"))
        checkMark.translatesAutoresizingMaskIntoConstraints = false
        checkMark.tintColor = .systemGreen
        return checkMark
    }()
    
    private let continueButton: CustomButton = {
        let button = CustomButton()
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
        switch activeViewIndex {
        case 1:
            continueToUsernameView()
        case 2:
            continueToPasswordView()
        case 3:
            continueToProfileGeneralCardView()
        case 4:
            continueToAgeGenderCardView()
        case 5:
            finishRegistration()
        default:
            print("Out of index")
        }
    }
    
    func continueToUsernameView() {
        let email = emailView.getTextFieldData()
        
        if viewModel.isValidEmail(email: email) {
            
            viewModel.checkIfEmailIsAvailable(email: email) { isAvailable, description in
                
                if isAvailable {
                    UIView.animate(withDuration: 0.5) {
                        let x = self.emailView.frame.maxX
                        self.scrollView.setContentOffset(CGPoint(x: x , y: 0), animated: false)
                    }
                    self.activeViewIndex += 1
                    
                } else {
                    self.emailView.showErrorNotification(error: description)
                }
            }
            
        } else {
            emailView.showErrorNotification(error: "Invalid email")
        }
    }
    
    func continueToPasswordView() {
        let username = usernameView.getTextFieldData()
        viewModel.checkIfUsernameIsAvailable(username: username) { isAvailable in
            if isAvailable {
                UIView.animate(withDuration: 0.5) {
                    let x = self.usernameView.frame.maxX
                    self.scrollView.setContentOffset(CGPoint(x: x , y: 0), animated: false)
                }
                self.activeViewIndex += 1
            } else {
                self.usernameView.showErrorNotification(error: "Username already taken")
            }
        }
    }
    
    func continueToProfileGeneralCardView() {
        let email = emailView.getTextFieldData()
        let username = usernameView.getTextFieldData()
        let password = passwordView.getTextFieldData()
        viewModel.registerNewUserWith(email: email, username: username, password: password) { sucess, errorDescription in
            if sucess {
                print("Succesfully registered")
                self.showGeneralProfileInfoCardView()
                self.activeViewIndex += 1
            } else {
                self.passwordView.showErrorNotification(error: errorDescription)
            }
        }
    }
    
    func continueToAgeGenderCardView() {
        let name = generalProfileInfoCardView.getName()
        let bio = generalProfileInfoCardView.getBio()
        let profilePicture = generalProfileInfoCardView.getProfilePicture()
        viewModel.addUserInfo(name: name, bio: bio, profilePic: profilePicture) {
            print("Succesfully added name, bio, profile pic")
            self.showAgeGenderCardView()
            self.activeViewIndex += 1
        }
    }
    
    func finishRegistration() {
        let dateOfBirth = ageAndGenderView.getDateOfBirth()
        let gender = ageAndGenderView.getGender()
        
        viewModel.finishSignUp(dateOfBirth: dateOfBirth, gender: gender) {
            print("succesfully added date of birth and gender")
            self.showMainScreen()
        }
    }
    
    
    func showGeneralProfileInfoCardView() {
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
        view.addSubview(containerView)
        containerView.addSubview(generalProfileInfoCardView)
        containerView.addSubview(ageAndGenderView)
        generalProfileInfoCardView.setupDelegates(viewController: self)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -50),
            containerView.heightAnchor.constraint(equalToConstant: 360),
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            generalProfileInfoCardView.topAnchor.constraint(equalTo: containerView.topAnchor),
            generalProfileInfoCardView.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            generalProfileInfoCardView.heightAnchor.constraint(equalTo: containerView.heightAnchor),
            generalProfileInfoCardView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            ageAndGenderView.topAnchor.constraint(equalTo: containerView.topAnchor),
            ageAndGenderView.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            ageAndGenderView.heightAnchor.constraint(equalTo: containerView.heightAnchor),
            ageAndGenderView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
        
        containerView.transform = CGAffineTransform(translationX: view.frame.width, y: 0)
        
        UIView.animateKeyframes(withDuration: 0.7, delay: 0) {
            
            //Hide scrollView
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.3) {
                self.scrollView.alpha = 0
                self.scrollView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
            }
            
            //Move continue button to the bottom and slide in containerView of GeneralProfileInfo and AgeGender card views
            UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.3) {
                //Rebinding continue button constraint from scrollView to containerView
                self.continueButtonYAnchorConstraint.isActive = false
                self.continueButtonYAnchorConstraint = self.continueButton.topAnchor.constraint(equalTo: self.containerView.bottomAnchor, constant: 20)
                self.continueButtonYAnchorConstraint.isActive = true
                self.view.layoutIfNeeded()
            }
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.4) {
                self.containerView.transform = CGAffineTransform.identity
            }
        } completion: { _ in
            self.scrollView.removeFromSuperview()
        }
    }
    
    func showAgeGenderCardView() {
        self.continueButton.setTitle("Finish", for: .normal)
        let transitionOptions: UIView.AnimationOptions = [.transitionFlipFromRight, .showHideTransitionViews]
        UIView.transition(from: generalProfileInfoCardView, to: ageAndGenderView, duration: 1.0, options: transitionOptions)
        addCheckMark()
    }
    
    func showMainScreen() {
        UIView.animateKeyframes(withDuration: 1.3, delay: 0) {
            self.checkMark.isHidden = false
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.4) {
                
                self.containerView.transform = CGAffineTransform(translationX: 0, y: -(self.view.frame.height - self.containerView.frame.height))
                
                self.continueButtonYAnchorConstraint.isActive = false
                self.continueButtonYAnchorConstraint = self.continueButton.topAnchor.constraint(equalTo: self.view.bottomAnchor)
                self.continueButtonYAnchorConstraint.isActive = true
                self.view.layoutIfNeeded()
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.4) {
                self.view.alpha = 0
            }
        } completion: { _ in
            self.view.window?.rootViewController = TabBarController(showAppearAnimation: true)
            self.view.window?.makeKeyAndVisible()
        }
    }
    
    func addCheckMark() {
        view.addSubview(checkMark)
        
        NSLayoutConstraint.activate([
            checkMark.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            checkMark.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            checkMark.widthAnchor.constraint(equalToConstant: 110),
            checkMark.heightAnchor.constraint(equalToConstant: 110)
        ])
        checkMark.layer.zPosition = containerView.layer.zPosition - 1
        checkMark.isHidden = true
    }
    
    func setupScrollView() {
        scrollView.contentSize = CGSize(width: view.frame.width * 3, height: scrollViewHeight)
    }
    
    func setupConstraints() {
        let continueButtonYAnchorConstraint = continueButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 20)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
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



extension RegistrationVC: ProfilePictureHeaderProtocol{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.generalProfileInfoCardView.updateProfileHeaderPicture(with: selectedImage)
        }
    }
}
