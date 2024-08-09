//
//  ProfilePictureCell.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 10.01.2024.
//

import UIKit.UITableView

class ProfilePictureCell: UITableViewCell {

    weak var delegate: ProfilePictureViewDelegate? {
        didSet {
            profilePictureView.delegate = self.delegate
        }
    }

    private let profilePictureView: ProfilePictureView = {
        let view = ProfilePictureView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        profilePictureView.delegate = self.delegate
        backgroundColor = Colors.naturalBackground
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        contentView.addSubview(profilePictureView)
        NSLayoutConstraint.activate([
            profilePictureView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            profilePictureView.heightAnchor.constraint(equalToConstant: 170),
            profilePictureView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            profilePictureView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
            profilePictureView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    func configure(with profileImage: UIImage) {
        profilePictureView.configure(with: profileImage)
    }
}
