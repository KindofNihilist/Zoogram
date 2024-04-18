//
//  CameraRollSectionHeaderView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 16.11.2023.
//

import UIKit

protocol CameraRollHeaderDelegate: UIImagePickerControllerDelegate, UINavigationControllerDelegate, AnyObject {
    func didTapCameraButton(_ header: CameraRollHeaderView)
}

class CameraRollHeaderView: UICollectionReusableView {
    
    weak var delegate: CameraRollHeaderDelegate?
    
    static var identifier: String {
        return String(describing: self)
    }
    
    private let padding: CGFloat = 15
    
    private lazy var cameraButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.masksToBounds = true
        button.setImage(UIImage(systemName: "camera"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .darkGray
        button.addTarget(self, action: #selector(didTapCameraButton), for: .touchUpInside)
        return button
    }()

    private let sortButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(String(localized: "Recents"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = CustomFonts.boldFont(ofSize: 16)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = .black
        setupCameraRollHeader()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        cameraButton.layer.cornerRadius = (self.bounds.height - padding) / 2
    }
    
    private func setupCameraRollHeader() {
        addSubviews(sortButton, cameraButton)

        NSLayoutConstraint.activate([
            sortButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            sortButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: padding),
            sortButton.heightAnchor.constraint(equalTo: self.heightAnchor),
            sortButton.trailingAnchor.constraint(lessThanOrEqualTo: self.cameraButton.leadingAnchor),

            cameraButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            cameraButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -padding),
            cameraButton.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -padding),
            cameraButton.widthAnchor.constraint(equalTo: self.heightAnchor, constant: -padding)
        ])
    }
}

extension CameraRollHeaderView {
    @objc private func didTapCameraButton() {
        delegate?.didTapCameraButton(self)
    }
}
