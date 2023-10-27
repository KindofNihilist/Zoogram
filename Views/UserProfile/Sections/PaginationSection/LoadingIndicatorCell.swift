//
//  LoadingIndicatorself.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 25.10.2023.
//

import UIKit

class LoadingIndicatorController: GenericCellController<LoadingIndicatorCell> {
    override func configureCell(_ cell: LoadingIndicatorCell) {
        cell.spinner.startAnimating()
    }
}

class LoadingIndicatorCell: UICollectionViewCell {

    let spinner = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(spinner)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            spinner.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            spinner.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            spinner.topAnchor.constraint(equalTo: self.topAnchor),
            spinner.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
}
