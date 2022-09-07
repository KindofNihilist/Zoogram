//
//  ProfileEditTableViewHeader.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 19.01.2022.
//

import UIKit

class ProfileEditTableViewHeader: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubviews(imageView, changeProfilePicButton)
        setupSubviews()
    }
    
    private let imageWidthHeight: CGFloat = 115
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let imageView: UIImageView = {
       let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "person.crop.circle.fill")
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = .systemGray5
        return imageView
    }()
    
    let changeProfilePicButton: UIButton = {
        let button = UIButton()
        button.setTitle("Choose profile photo", for: .normal)
        button.setTitleColor(.link, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    public func configure(with image: UIImage?) {
        guard let image = image else {
           return
        }
        imageView.image = image
    }
    
    public func getChosenProfilePic() -> UIImage {
        return imageView.image!
    }
    
    private func setupSubviews() {
        NSLayoutConstraint.activate([
            imageView.bottomAnchor.constraint(equalTo: changeProfilePicButton.topAnchor, constant: -10),
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: imageWidthHeight),
            imageView.heightAnchor.constraint(equalToConstant: imageWidthHeight),
            
            changeProfilePicButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20),
            changeProfilePicButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            changeProfilePicButton.heightAnchor.constraint(equalToConstant: 20),
            changeProfilePicButton.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -20)
        ])
        imageView.layer.cornerRadius = imageWidthHeight / 2
    }
}
