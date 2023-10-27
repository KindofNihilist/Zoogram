//
//  NoPostsAlertView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 17.10.2022.
//

import UIKit

class PlaceholderView: UIView {

    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .label
        imageView.contentMode = .scaleAspectFit
//        imageView.backgroundColor = .systemRed
        return imageView
    }()

    let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .rounded(ofSize: 23, weight: .bold)
        label.numberOfLines = 0
        label.textAlignment = .center
//        label.backgroundColor = .systemOrange
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
//        self.backgroundColor = .green
    }

    convenience init(imageName: String, text: String) {
        self.init(frame: CGRect.zero)
        self.addSubviews(imageView, label)
        imageView.image = UIImage(systemName: imageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 70))
        setupConstraints()

        let attributedString = NSMutableAttributedString(string: text)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        paragraphStyle.alignment = .center
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))

        self.label.attributedText = attributedString
    }

    override func layoutSubviews() {
        label.sizeToFit()
        imageView.sizeToFit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),

            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 15),
            label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 25),
            label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -25),
            label.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor)
        ])
    }

}
