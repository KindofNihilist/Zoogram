//
//  NoNotificationView.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 21.01.2022.
//

import UIKit

class NoNotificationsView: UIView {
    
    private let label: UILabel = {
        let label = UILabel()
        label.text = String(localized: "No Notifications")
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.font = CustomFonts.boldFont(ofSize: 17)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "bell.slash")
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViewsAndConstraints()
        backgroundColor = Colors.background
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViewsAndConstraints() {
        addSubviews(imageView, label)
        
        NSLayoutConstraint.activate([
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -80),
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 55),
            imageView.widthAnchor.constraint(equalToConstant: 55),
            
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            label.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            label.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor),
            label.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor)
        ])
    }
}
