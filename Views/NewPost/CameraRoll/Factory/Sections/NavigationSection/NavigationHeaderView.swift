//
//  NavigationHeaderView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 17.11.2023.
//

import UIKit.UICollectionView

protocol NavigationHeaderActionsDelegate: AnyObject {
    func didTapBackButton()
    func didTapNextButton()
}

class NavigationHeaderView: UICollectionReusableView {

    weak var delegate: NavigationHeaderActionsDelegate?

    static var identifier: String {
        return String(describing: self)
    }

    private lazy var navigationBackButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.addTarget(self, action: #selector(didTapBackButton), for: .touchUpInside)
        return button
    }()

    private lazy var navigationTitle: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.tintColor = Colors.background
        label.textColor = .white
        label.font = CustomFonts.boldFont(ofSize: 17)
        return label
    }()

    private lazy var navigationNextButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = CustomFonts.boldFont(ofSize: 17)
        button.tintColor = .systemBlue
        button.setTitleColor(.systemBlue, for: .normal)
        button.addTarget(self, action: #selector(didTapNextButton), for: .touchUpInside)
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
        self.backgroundColor = .black
        self.navigationTitle.text = String(localized: "New Post")
        self.navigationNextButton.setTitle(String(localized: "Next"), for: .normal)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.addSubviews(navigationBackButton, navigationTitle, loadingIndicator, navigationNextButton)

        NSLayoutConstraint.activate([
            navigationBackButton.topAnchor.constraint(equalTo: self.topAnchor),
            navigationBackButton.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            navigationBackButton.trailingAnchor.constraint(lessThanOrEqualTo: self.navigationTitle.leadingAnchor, constant: -15),
            navigationBackButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
            navigationBackButton.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -5),

            navigationTitle.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            navigationTitle.topAnchor.constraint(equalTo: self.topAnchor),
            navigationTitle.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -5),

            navigationNextButton.leadingAnchor.constraint(greaterThanOrEqualTo: navigationTitle.trailingAnchor, constant: 15),
            navigationNextButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
            navigationNextButton.topAnchor.constraint(equalTo: self.topAnchor),
            navigationNextButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
            navigationNextButton.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -5),

            loadingIndicator.leadingAnchor.constraint(greaterThanOrEqualTo: navigationTitle.trailingAnchor, constant: 15),
            loadingIndicator.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            loadingIndicator.topAnchor.constraint(equalTo: self.topAnchor),
            loadingIndicator.heightAnchor.constraint(equalTo: self.heightAnchor)
        ])
    }

    func showLoadingIndicator() {
        navigationNextButton.isHidden = true
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
    }

    func showNextButton() {
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
        navigationNextButton.isHidden = false
    }

    @objc private func didTapBackButton() {
        delegate?.didTapBackButton()
    }

    @objc private func didTapNextButton() {
        delegate?.didTapNextButton()
    }
}
