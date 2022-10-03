//
//  ProfileTabsCollectionReusableView.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 20.01.2022.
//

import UIKit

protocol ProfileTabsCollectionViewDelegate: AnyObject {
    func didTapGridTabButton()
    func didTapTaggedTabButton()
}

class ProfileTabsReusableView: UICollectionReusableView {
    
    static let identifier = "ProfileTabsCollectionReusableView"
    
    public weak var delegate: ProfileTabsCollectionViewDelegate?
    
    private let personalFeedButton: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "squareshape.split.3x3"), for: .normal)
        button.tintColor = .label
        return button
    }()
    
    private let taggedButton: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "person.2.fill"), for: .normal)
        button.tintColor = .lightGray
        return button
    }()
    
    private let separator: UIView = {
        let view = UIView()
        view.backgroundColor = .label
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews(personalFeedButton, taggedButton)
        setupConstraints()
        personalFeedButton.addTarget(self, action: #selector(didTapGridButton), for: .touchUpInside)
        taggedButton.addTarget(self, action: #selector(didTapTaggedButton), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            personalFeedButton.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            personalFeedButton.topAnchor.constraint(equalTo: self.topAnchor),
            personalFeedButton.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            personalFeedButton.trailingAnchor.constraint(equalTo: self.centerXAnchor),
            
            taggedButton.leadingAnchor.constraint(equalTo: self.centerXAnchor),
            taggedButton.topAnchor.constraint(equalTo: self.topAnchor),
            taggedButton.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            taggedButton.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
    
    @objc private func didTapGridButton() {
        personalFeedButton.tintColor = .label
        taggedButton.tintColor = .lightGray
        delegate?.didTapGridTabButton()
         
    }
    
    @objc private func didTapTaggedButton() {
        personalFeedButton.tintColor = .lightGray
        taggedButton.tintColor = .label
        delegate?.didTapTaggedTabButton()
    }
    
    
        
}
