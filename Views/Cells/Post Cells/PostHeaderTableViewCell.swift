//
//  PostHeaderTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 25.01.2022.
//

import SDWebImage
import UIKit

class PostHeaderTableViewCell: UITableViewCell {
    
    static let identifier = "PostHeaderTableViewCell"
    
    private let profilePhotoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()
    
    private let usernameLabel: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .label
        return label
    }()
    
    private let menuButton: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "square.and.arrow.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 19)), for: .normal)
        button.tintColor = .label
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .systemBackground
        contentView.clipsToBounds = true
        setupViewsAndConstraints()
    }
    
    public func configure(with userModel: User) {
        profilePhotoImageView.sd_setImage(with: URL(string: userModel.profilePhotoURL), completed: nil)
        usernameLabel.text = userModel.username
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setupViewsAndConstraints() {
        contentView.addSubviews(profilePhotoImageView, usernameLabel, menuButton)
        
        let profilePhotoHeightWidth = frame.height - 10
        
        NSLayoutConstraint.activate([
            profilePhotoImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profilePhotoImageView.heightAnchor.constraint(equalToConstant: profilePhotoHeightWidth),
            profilePhotoImageView.widthAnchor.constraint(equalToConstant: profilePhotoHeightWidth),
            profilePhotoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            
            usernameLabel.centerYAnchor.constraint(equalTo: profilePhotoImageView.centerYAnchor),
            usernameLabel.leadingAnchor.constraint(equalTo: profilePhotoImageView.trailingAnchor, constant: 10),
            usernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: menuButton.leadingAnchor),
            usernameLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor),
            
            menuButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            menuButton.heightAnchor.constraint(equalTo: contentView.heightAnchor),
            menuButton.widthAnchor.constraint(equalToConstant: contentView.frame.height),
            menuButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        
        profilePhotoImageView.layer.cornerRadius = profilePhotoHeightWidth / 2
    }
}
