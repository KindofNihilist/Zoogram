//
//  NavigationBar.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 26.06.2024.
//

import UIKit

class NavigationBar: UIView {

    var leftButtonAction: (() -> Void)?
    var rightButtonAction: (() -> Void)?

    var leftButtonTitle: String? {
        didSet {
            leftButton.setTitle(leftButtonTitle, for: .normal)
        }
    }

    var leftButtonImage: UIImage? {
        didSet {
            leftButton.setImage(leftButtonImage, for: .normal)
        }
    }

    var rightButtonTitle: String? {
        didSet {
            rightButton.setTitle(rightButtonTitle, for: .normal)
            rightButton.isHidden = false
        }
    }

    var rightButtonImage: UIImage? {
        didSet {
            rightButton.setImage(rightButtonImage, for: .normal)
            rightButton.isHidden = false
        }
    }

    var title: String? {
        didSet {
            titleLabel.text = title
            titleLabel.isHidden = false
        }
    }

    lazy var leftButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = Colors.label
        button.setImage(withSystemName: "chevron.backward", pointSize: 23, weight: .medium)
        button.addTarget(self, action: #selector(didTapLeftButton), for: .touchUpInside)
        return button
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.tintColor = Colors.label
        label.font = CustomFonts.boldFont(ofSize: 17)
        label.isHidden = true
        return label
    }()

    lazy var rightButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = CustomFonts.boldFont(ofSize: 17)
        button.tintColor = Colors.label
        button.setTitleColor(.systemBlue, for: .normal)
        button.addTarget(self, action: #selector(didTapRightButton), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let loadingIndicator = UIActivityIndicatorView()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = .white
        loadingIndicator.isHidden = true
        return loadingIndicator
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.addSubviews(leftButton, titleLabel, loadingIndicator, rightButton)

        NSLayoutConstraint.activate([
            leftButton.topAnchor.constraint(equalTo: self.topAnchor),
            leftButton.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            leftButton.trailingAnchor.constraint(lessThanOrEqualTo: self.titleLabel.leadingAnchor, constant: -15),
            leftButton.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -5),
            leftButton.widthAnchor.constraint(equalTo: self.heightAnchor, constant: -5),

            titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: self.topAnchor),
            titleLabel.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -5),

            rightButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 15),
            rightButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
            rightButton.topAnchor.constraint(equalTo: self.topAnchor),
            rightButton.widthAnchor.constraint(equalTo: self.heightAnchor, constant: -5),
            rightButton.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -5),

            loadingIndicator.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 15),
            loadingIndicator.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            loadingIndicator.topAnchor.constraint(equalTo: self.topAnchor),
            loadingIndicator.heightAnchor.constraint(equalTo: self.heightAnchor)
        ])
    }

    func showLoadingIndicator() {
        rightButton.isHidden = true
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
    }

    func showNextButton() {
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
        rightButton.isHidden = false
    }

    @objc private func didTapLeftButton() {
        leftButtonAction?()
    }

    @objc private func didTapRightButton() {
        rightButtonAction?()
    }
}
