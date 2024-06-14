//
//  LoadingErrorNotificationView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 26.03.2024.
//

import UIKit

@MainActor protocol LoadingErrorViewDelegate: AnyObject {
    func didTapReloadButton()
}

class LoadingErrorView: UIView {

    private var reloadButtonSize: CGSize

    weak var delegate: LoadingErrorViewDelegate?

    var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = CustomFonts.boldFont(ofSize: 16)
        label.textColor = UIColor.secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    lazy var reloadButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "arrow.circlepath"), for: .normal)
        button.tintColor = UIColor.tertiaryLabel
        button.imageView?.contentMode = .scaleAspectFit
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.addTarget(self, action: #selector(didTapReloadButton), for: .touchUpInside)
        return button
    }()

    init(frame: CGRect = CGRect.zero, reloadButtonSize: CGSize = CGSize(width: 30, height: 30)) {
        self.reloadButtonSize = reloadButtonSize
        super.init(frame: frame)
        self.addSubviews(descriptionLabel, reloadButton)
        self.setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor),
            descriptionLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),

            reloadButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
            reloadButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            reloadButton.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 15),
            reloadButton.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor),
            reloadButton.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor),
            reloadButton.widthAnchor.constraint(equalToConstant: reloadButtonSize.width),
            reloadButton.heightAnchor.constraint(equalToConstant: reloadButtonSize.height),
            reloadButton.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor)
        ])
    }

    func setDescriptionLabelText(_ text: String) {
        self.descriptionLabel.text = text
    }

    @objc private func didTapReloadButton() {
        delegate?.didTapReloadButton()
    }
}
