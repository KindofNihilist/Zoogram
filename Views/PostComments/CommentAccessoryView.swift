//
//  CommentsAccessoryView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.01.2023.
//

import UIKit

protocol CommentAccessoryViewProtocol {
    func postButtonTapped(commentText: String)
}

class CommentAccessoryView: UIView {
    
    var delegate: CommentAccessoryViewProtocol?
    
    var userProfilePicture: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()
    
    var commentTextField: AccessoryViewTextField = {
        let textField = AccessoryViewTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = .secondarySystemBackground
        textField.placeholder = "Enter comment"
        textField.clipsToBounds = true
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.placeholderText.cgColor
        return textField
    }()
    
    var postButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 30).isActive = true
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        button.clipsToBounds = true
        button.layer.cornerRadius = 30/2
        button.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 35)), for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(self, action: #selector(didTapPostButton), for: .touchUpInside)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupConstraints()
        backgroundColor = .systemBackground
        commentTextField.rightView = postButton
        commentTextField.rightViewMode = .always
        autoresizingMask = .flexibleHeight
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setViewCornerRadius()
    }
    
    func setViewCornerRadius() {
        userProfilePicture.layer.cornerRadius = userProfilePicture.frame.height / 2
        commentTextField.layer.cornerRadius = commentTextField.frame.height / 2
    }
    func setupConstraints() {
        self.addSubviews(userProfilePicture, commentTextField)
        
        NSLayoutConstraint.activate([
            
            userProfilePicture.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            userProfilePicture.centerYAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerYAnchor),
            userProfilePicture.widthAnchor.constraint(equalToConstant: 40),
            userProfilePicture.heightAnchor.constraint(equalToConstant: 40),
            
            commentTextField.leadingAnchor.constraint(equalTo: userProfilePicture.trailingAnchor, constant: 10),
            commentTextField.centerYAnchor.constraint(equalTo: userProfilePicture.centerYAnchor),
            commentTextField.heightAnchor.constraint(equalToConstant: 40),
            commentTextField.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            
        ])
    }
    
    override var intrinsicContentSize: CGSize {
        return .zero
    }
    
    //    override func didMoveToWindow() {
    //        if #available(iOS 11.0, *) {
    //            if let window = window {
    //                let bottomAnchor = bottomAnchor.constraint(lessThanOrEqualToSystemSpacingBelow: window.safeAreaLayoutGuide.bottomAnchor, multiplier: 1.0)
    //                bottomAnchor.isActive = true
    //            }
    //        }
    //    }
    
    @objc func didTapPostButton() {
        guard let text = commentTextField.text else {
            return
        }
        commentTextField.resignFirstResponder()
        delegate?.postButtonTapped(commentText: text)
    }
}
