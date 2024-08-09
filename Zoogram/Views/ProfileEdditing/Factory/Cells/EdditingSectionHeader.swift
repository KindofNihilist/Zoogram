//
//  EditProfileSectionHeader.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 20.01.2022.
//

import UIKit

class ProfileEdditingSectionHeader: UITableViewHeaderFooterView {
    static let identifier = "EditProfileSectionHeader"

    let title = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        backgroundColor = .blue
        configureContents()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureContents() {
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = CustomFonts.boldFont(ofSize: 19)
        title.textColor = Colors.label
        title.textAlignment = .left

        contentView.addSubview(title)
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor, constant: 20),
            title.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            title.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            title.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -15)
        ])
    }
}
