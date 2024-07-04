//
//  NavigationHeaderView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 17.11.2023.
//

import UIKit.UICollectionView

class NavigationReusableView: UICollectionReusableView {

    static var identifier: String {
        return String(describing: self)
    }

    let navigationView = NavigationBar()

    override init(frame: CGRect) {
        super.init(frame: frame)
        navigationView.translatesAutoresizingMaskIntoConstraints = false
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.addSubview(navigationView)
        NSLayoutConstraint.activate([
            navigationView.topAnchor.constraint(equalTo: self.topAnchor),
            navigationView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            navigationView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            navigationView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }

    func showLoadingIndicator() {
        navigationView.showLoadingIndicator()
    }

    func showNextButton() {
        navigationView.showNextButton()
    }
}
