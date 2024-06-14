//
//  NewPostPlaceholderTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 22.01.2024.
//

import UIKit

class NewPostPlaceholderTableViewCell: UITableViewCell {

    static let identifier = "NewPostPlaceholderCell"

    let blankView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(blankView)
        NSLayoutConstraint.activate([
            blankView.topAnchor.constraint(equalTo: contentView.topAnchor),
            blankView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            blankView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            blankView.heightAnchor.constraint(equalToConstant: PostTableViewCell.headerHeight),
            blankView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}
