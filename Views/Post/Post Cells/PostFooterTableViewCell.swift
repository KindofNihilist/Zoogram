//
//  PostFooterTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 26.01.2022.
//

import UIKit

class PostFooterTableViewCell: UITableViewCell {
    
    static let identifier = "PostFooterTableViewCell"
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 10
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let likesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var captionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        //        label.topAnchor.constraint(equalTo: likesLabel.bottomAnchor, constant: 10).isActive = true
        label.heightAnchor.constraint(equalToConstant: 20).isActive = true
        label.widthAnchor.constraint(equalToConstant: contentView.frame.width).isActive = true
        //        label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
        //        label.trailingAnchor.constraint(lessThanOrEqualTo: stackView.trailingAnchor, constant: -15).isActive = true
        return label
    }()
    
    private lazy var viewCommentsButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .left
        //        button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
        //        button.trailingAnchor.constraint(lessThanOrEqualTo: stackView.trailingAnchor, constant: -15).isActive = true
        button.widthAnchor.constraint(equalToConstant: 200).isActive = true
        button.heightAnchor.constraint(equalToConstant: 15).isActive = true
        return button
    }()
    
    private let timeSincePostedLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .systemBackground
    }
    
    public func configure(for post: UserPost, username: String) {
        var views = [UIView]()
        views.append(likesLabel)
        
        if !post.caption.isEmpty {
            let attributedUsername = NSAttributedString(string: "\(username) ", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.label])
            let attributedCaption = NSAttributedString(string: post.caption, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.label])
            
            let usernameWithCaption = NSMutableAttributedString()
            usernameWithCaption.append(attributedUsername)
            usernameWithCaption.append(attributedCaption)
            captionLabel.attributedText = usernameWithCaption
            views.append(captionLabel)
        }
        
            views.append(viewCommentsButton)
        
        let formattedDate = post.postedDate.formatted(date: .abbreviated, time: .omitted)
        timeSincePostedLabel.text = "\(formattedDate)"
        
        views.append(timeSincePostedLabel)
        
        for view in views {
            stackView.addArrangedSubview(view)
        }
        contentView.addSubview(stackView)
        setupConstraints()
    }
    
    func setLikes(likesCount: Int) {
        if likesCount == 1 {
            likesLabel.text = "\(likesCount) like"
        } else {
            likesLabel.text = "\(likesCount) likes"
        }
    }

    func setComments(commentsCount: Int) {
        if commentsCount > 1 {
            viewCommentsButton.setTitle("View all \(commentsCount) comments", for: .normal)
        } else {
            viewCommentsButton.setTitle("View \(commentsCount) comment", for: .normal)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            likesLabel.topAnchor.constraint(equalTo: stackView.topAnchor, constant: 5),
            likesLabel.heightAnchor.constraint(equalToConstant: 15),
            likesLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            likesLabel.trailingAnchor.constraint(lessThanOrEqualTo: stackView.trailingAnchor, constant: -15),
            
            timeSincePostedLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            timeSincePostedLabel.trailingAnchor.constraint(lessThanOrEqualTo: stackView.trailingAnchor),
            timeSincePostedLabel.heightAnchor.constraint(equalToConstant: 15),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
