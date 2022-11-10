//
//  PostActionsTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 25.01.2022.
//

import UIKit

protocol PostActionsDelegate {
    func didTapLikeButton(postID: String, postActionsView: PostActionsTableViewCell)
    func didTapCommentButton()
    func didTapBookmarkButton()
}

class PostActionsTableViewCell: UITableViewCell {
    
    var postID = ""
    var likeState: PostLikeState!
    
    var delegate: PostActionsDelegate?
    
    
    private let likeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "heart", withConfiguration: UIImage.SymbolConfiguration(pointSize: 29)), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .label
        button.backgroundColor = .systemBackground
        button.addTarget(self, action: #selector(didTapLikeButton), for: .touchUpInside)
        return button
    }()
    
    private let commentButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "bubble.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 29)), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .label
        button.backgroundColor = .systemBackground
        return button
    }()
    
    private let bookmarkButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "bookmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 29)), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
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
    
    func configureLikeButton(likeState: PostLikeState) {
        self.likeState = likeState
        switch likeState {
        case .liked:
            showLikedButton(animated: false)
        case .notLiked:
            showLikeButton(animated: false)
        }
    }
    
    func switchLikeButton() {
        switch likeState {
            
        case .liked:
            showLikeButton()
        case .notLiked:
            showLikedButton()
        case .none:
            print("Like state isn't initialized")
            return
        }
    }
    
    func showLikeButton(animated: Bool = true) {
        if animated {
            UIView.animateKeyframes(withDuration: 0.2, delay: 0) {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                    self.likeButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.likeButton.transform = .identity
                    self.likeButton.setImage(UIImage(systemName: "heart", withConfiguration: UIImage.SymbolConfiguration(pointSize: 29)), for: .normal)
                    self.likeButton.tintColor = .label
                }
            }
        } else {
            likeButton.setImage(UIImage(systemName: "heart", withConfiguration: UIImage.SymbolConfiguration(pointSize: 29)), for: .normal)
            likeButton.tintColor = .label
        }
        
    }
    
    func showLikedButton(animated: Bool = true) {
        if animated {
            UIView.animateKeyframes(withDuration: 0.2, delay: 0) {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                    self.likeButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.likeButton.transform = .identity
                    self.likeButton.setImage(UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 29)), for: .normal)
                    self.likeButton.tintColor = .systemRed
                }
            }
        } else {
            likeButton.setImage(UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 29)), for: .normal)
            likeButton.tintColor = .systemRed
        }
    }
    
    
    
    private func setupViewAndConstraints() {
        contentView.addSubviews(likeButton, commentButton, bookmarkButton)
        
        let cellHeight = frame.height
        
        NSLayoutConstraint.activate([
            likeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 13),
            likeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            likeButton.widthAnchor.constraint(equalToConstant: 30),
            likeButton.heightAnchor.constraint(equalToConstant: 30),
            
            commentButton.leadingAnchor.constraint(equalTo: likeButton.trailingAnchor, constant: 10),
            commentButton.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor),
            commentButton.widthAnchor.constraint(equalToConstant: 30),
            commentButton.heightAnchor.constraint(equalToConstant: 30),
            
            bookmarkButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            bookmarkButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            bookmarkButton.widthAnchor.constraint(equalToConstant: 30),
            bookmarkButton.heightAnchor.constraint(equalToConstant: 30),
        ])
    }
    
    @objc func didTapLikeButton() {
        switchLikeButton()
        delegate?.didTapLikeButton(postID: self.postID, postActionsView: self)
    }
}
