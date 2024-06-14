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
        imageView.tintColor = Colors.label
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = CustomFonts.boldFont(ofSize: 18)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = Colors.label
        return label
    }()

    convenience init(imageName: String, text: String, imagePointSize: CGFloat = 52 ) {
        self.init(frame: CGRect.zero)
        self.addSubviews(imageView, label)
        imageView.image = UIImage(systemName: imageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: imagePointSize))
        setupConstraints()

        let attributedString = NSMutableAttributedString(string: text)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        paragraphStyle.alignment = .center
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle,
                                      value: paragraphStyle,
                                      range: NSRange(location: 0, length: attributedString.length))

        self.label.attributedText = attributedString
    }

    override func layoutSubviews() {
        label.sizeToFit()
        imageView.sizeToFit()
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),

            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 25),
            label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -25),
            label.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor)
        ])
    }

}
