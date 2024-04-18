//
//  ProfilePictureImageView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 09.04.2024.
//

import UIKit

class ProfilePictureImageView: UIImageView {

    init() {
        super.init(frame: CGRect.zero)
        self.clipsToBounds = true
        self.image = UIImage(systemName: "person.crop.circle.fill")
        self.contentMode = .scaleAspectFit
        self.tintColor = Colors.profilePicturePlaceholder
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
