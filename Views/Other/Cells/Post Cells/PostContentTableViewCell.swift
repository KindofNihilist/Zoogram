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
    
    var cellHeightConstraint: NSLayoutConstraint!
    
    let postImageView: UIImageView = {
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
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(with image: UIImage) {
//        postImageView.sd_setImage(with: URL(string: photoURL)) { image, error, cache, url in
//            if let downloadedImage = image {
//                let imageAspectRatio = downloadedImage.size.width / downloadedImage.size.height
//                self.setupImageViewConstraints(for: imageAspectRatio)
//            }
//        }
        postImageView.image = image
        let imageAspectRatio = image.size.width / image.size.height
        setupImageViewHeightConstraint(for: imageAspectRatio)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        postImageView.sd_cancelCurrentImageLoad()
    }
    
    private func setupImageViewHeightConstraint(for imageAspectRatio: CGFloat) {
        cellHeightConstraint.isActive = false
        cellHeightConstraint = postImageView.heightAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1/imageAspectRatio)
        cellHeightConstraint.isActive = true
        self.layoutIfNeeded()
    }
    
    private func setupConstraints() {
        let heightConstraintDynamic = postImageView.heightAnchor.constraint(equalTo: contentView.widthAnchor)
        
        NSLayoutConstraint.activate([
            heightConstraintDynamic,
            postImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            postImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
        self.cellHeightConstraint = heightConstraintDynamic
    }
}
