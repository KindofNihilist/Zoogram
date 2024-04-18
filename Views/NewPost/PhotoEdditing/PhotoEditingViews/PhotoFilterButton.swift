//
//  PhotoFilterButton.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 21.11.2023.
//

import UIKit

class PhotoFilterButton: EdditingFilterButton {

    private let filterPreview: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let effectLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = CustomFonts.boldFont(ofSize: 13)
        label.textAlignment = .center
        label.textColor = .gray

        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews(filterPreview, effectLabel)
        setupConstraints()
        onStatusChange = { isRelatedEffectApplied in
            self.effectLabel.textColor = isRelatedEffectApplied ? .white : .gray
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            effectLabel.topAnchor.constraint(equalTo: self.topAnchor),
            effectLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            effectLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),

            filterPreview.topAnchor.constraint(equalTo: effectLabel.bottomAnchor, constant: 10),
            filterPreview.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor),
            filterPreview.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor),
            filterPreview.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor),
            filterPreview.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            filterPreview.widthAnchor.constraint(equalToConstant: 90),
            filterPreview.heightAnchor.constraint(equalToConstant: 90),

        ])
    }

    func configure(effectIcon: UIImage, effectName: String) {
        self.filterPreview.image = effectIcon
        self.effectLabel.text = effectName
    }
}
