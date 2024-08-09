//
//  PhotoCollectionViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 20.01.2022.
//
import SDWebImage
import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {

    static let identifier = "PhotoCollectionViewCell"

    let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(photoImageView)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            photoImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            photoImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    override func prepareForReuse() {
        self.photoImageView.image = nil
    }

    public func configure(using imageURL: URL) {
        photoImageView.sd_setImage(with: imageURL)
    }

    public func configure(using imageName: String) {
        photoImageView.image = UIImage(named: imageName)
    }

    public func configure(with image: UIImage) {
        photoImageView.image = image
    }

}
