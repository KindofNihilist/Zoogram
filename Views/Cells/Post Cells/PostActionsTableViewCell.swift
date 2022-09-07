//
//  PostActionsTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 25.01.2022.
//

import UIKit

class PostActionsTableViewCell: UITableViewCell {
    
    private let likeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "heart", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22)), for: .normal)
        button.tintColor = .label
        return button
    }()
    
    private let commentButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "message", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22)), for: .normal)
        button.tintColor = .label
        return button
    }()
    
    private let bookmarkButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "bookmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22)), for: .normal)
        button.tintColor = .label
        return button
    }()
    
    static let identifier = "PostActionsTableViewCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .systemBackground
        setupViewAndConstraints() 
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure() {
        
    }
    
    private func setupViewAndConstraints() {
        contentView.addSubviews(likeButton, commentButton, bookmarkButton)
        
        let cellHeight = frame.height
        
        NSLayoutConstraint.activate([
            likeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            likeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            likeButton.widthAnchor.constraint(equalToConstant: 30),
            likeButton.heightAnchor.constraint(equalToConstant: cellHeight),
            
            commentButton.leadingAnchor.constraint(equalTo: likeButton.trailingAnchor, constant: 10),
            commentButton.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor),
            commentButton.widthAnchor.constraint(equalToConstant: 30),
            commentButton.heightAnchor.constraint(equalToConstant: cellHeight),
            
            bookmarkButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            bookmarkButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            bookmarkButton.widthAnchor.constraint(equalToConstant: cellHeight),
            bookmarkButton.heightAnchor.constraint(equalToConstant: cellHeight),
        ])
    }
}
