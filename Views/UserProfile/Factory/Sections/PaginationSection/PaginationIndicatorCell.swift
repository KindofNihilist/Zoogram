//
//  LoadingIndicatorself.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 25.10.2023.
//

import UIKit

@MainActor protocol PaginationIndicatorCellDelegate: AnyObject {
    func didTapRetryPaginationButton()
}

class PaginationIndicatorController: GenericCellController<PaginationIndicatorCell> {

    override func configureCell(_ cell: PaginationIndicatorCell, at indexPath: IndexPath? = nil) {
        self.cell = cell
        cell.spinner.startAnimating()
    }
}

class PaginationIndicatorCell: UICollectionViewCell {

    weak var delegate: PaginationIndicatorCellDelegate?

    let spinner = UIActivityIndicatorView(style: .medium)

    lazy var loadingErrorView: LoadingErrorView = {
        let view = LoadingErrorView(reloadButtonSize: CGSize(width: 25, height: 25))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        view.descriptionLabel.font = CustomFonts.boldFont(ofSize: 14)
        return view
    }()

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
            spinner.topAnchor.constraint(equalTo: self.topAnchor),
            spinner.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            spinner.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            spinner.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }

    func showLoadingIndicator() {
        loadingErrorView.removeFromSuperview()
        spinner.startAnimating()
        spinner.alpha = 1
    }

    func displayLoadingError(_ error: Error) {
        spinner.stopAnimating()
        spinner.alpha = 0
        loadingErrorView.setDescriptionLabelText(error.localizedDescription)
        contentView.addSubview(loadingErrorView)
        NSLayoutConstraint.activate([
            loadingErrorView.topAnchor.constraint(equalTo: self.topAnchor),
            loadingErrorView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            loadingErrorView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            loadingErrorView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
}

extension PaginationIndicatorCell: LoadingErrorViewDelegate {
    func didTapReloadButton() {
        delegate?.didTapRetryPaginationButton()
    }
}
