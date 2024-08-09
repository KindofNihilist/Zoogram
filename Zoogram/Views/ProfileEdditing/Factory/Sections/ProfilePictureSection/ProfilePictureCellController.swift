//
//  ProfilePictureCellController.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 10.01.2024.
//

import UIKit.UIImage

class ProfilePictureCellController: GenericCellController<ProfilePictureCell> {

    weak var delegate: ProfilePictureViewDelegate?

    private var profilePicture: UIImage

    init(profilePicture: UIImage, delegate: ProfilePictureViewDelegate?) {
        self.profilePicture = profilePicture
        self.delegate = delegate
    }

    override func configureCell(_ cell: ProfilePictureCell, at indexPath: IndexPath? = nil) {
        cell.configure(with: profilePicture)
        cell.delegate = self.delegate
        cell.selectionStyle = .none
    }

    func updateProfilePicture(with image: UIImage) {
        self.profilePicture = image
    }
}
