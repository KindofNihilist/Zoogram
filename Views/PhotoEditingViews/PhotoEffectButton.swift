//
//  PhotoEffectButton.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 14.02.2022.
//

import UIKit

class PhotoEffectButton: UIButton {
    
    private let roundBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.systemFill.cgColor
        view.layer.cornerRadius = 42.5
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private let effectIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    
    private let effectLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews(roundBackgroundView, effectLabel)
        roundBackgroundView.addSubview(effectIcon)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            effectLabel.topAnchor.constraint(equalTo: self.topAnchor),
            effectLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            effectLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            effectLabel.bottomAnchor.constraint(lessThanOrEqualTo: roundBackgroundView.topAnchor),
            
            roundBackgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            roundBackgroundView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            roundBackgroundView.widthAnchor.constraint(equalTo: self.widthAnchor),
            roundBackgroundView.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -25),
            
            effectIcon.centerXAnchor.constraint(equalTo: roundBackgroundView.centerXAnchor),
            effectIcon.centerYAnchor.constraint(equalTo: roundBackgroundView.centerYAnchor),
            effectIcon.widthAnchor.constraint(equalToConstant: 45),
            effectIcon.heightAnchor.constraint(equalToConstant: 45),
        ])
        
    }
    
    public func configure(effectIcon: UIImage, effectName: String) {
        self.effectIcon.image = effectIcon
        self.effectLabel.text = effectName
        print(self.frame.width)
    }
    
    
}
