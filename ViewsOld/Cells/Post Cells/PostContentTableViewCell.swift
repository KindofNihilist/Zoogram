//
//  FeedPostTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 19.01.2022.
//

import SDWebImage
import UIKit

final class PostContentTableViewCell: UITableViewCell {
    
    static let identifier = "PostContentTableViewCell"
    
    private let postImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .systemBackground
        contentView.addSubview(postImageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(with image: UIImage?) {
        guard let image = image else {
            return
        }
        postImageView.image = image
        let imageAspectRatio = image.size.width / image.size.height
        setupImageViewConstraints(for: imageAspectRatio)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        postImageView.image = nil
    }
    
    private func setupImageViewConstraints(for imageAspectRatio: CGFloat) {
        NSLayoutConstraint.activate([
            postImageView.heightAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1/imageAspectRatio),
//            postImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            postImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            postImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
        ])
    }
}
