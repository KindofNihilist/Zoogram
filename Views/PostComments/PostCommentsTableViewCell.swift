//
//  PostCommentsTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 25.01.2022.
//

import UIKit

class PostCommentsTableViewCell: UITableViewCell {
    
    static let identifier = "PostCommentsTableViewCell"
    
    private let profilePhotoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .label
        label.font = UIFont.systemFont(ofSize: 13)
        label.text = "Wow what a cool post!"
        return label
    }()
    
    private let timePassedLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.text = "2h"
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .systemBackground
        setupViewsAndConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(with comment: PostComment) {
        
    }
    
    private func setupViewsAndConstraints() {
        contentView.addSubviews(profilePhotoImageView, messageLabel, timePassedLabel)
        
        NSLayoutConstraint.activate([
            profilePhotoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            profilePhotoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            profilePhotoImageView.heightAnchor.constraint(equalToConstant: 30),
            profilePhotoImageView.widthAnchor.constraint(equalToConstant: 30),
            
            messageLabel.topAnchor.constraint(equalTo: profilePhotoImageView.topAnchor),
            messageLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: profilePhotoImageView.trailingAnchor, constant: 10),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            
            timePassedLabel.leadingAnchor.constraint(equalTo: messageLabel.leadingAnchor),
            timePassedLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 5),
            timePassedLabel.heightAnchor.constraint(equalToConstant: 10),
            timePassedLabel.widthAnchor.constraint(equalToConstant: 20),
        ])
        
        profilePhotoImageView.layer.cornerRadius = 15
    }
}
 
