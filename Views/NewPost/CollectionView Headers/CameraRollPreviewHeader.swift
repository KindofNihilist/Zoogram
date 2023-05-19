//
//  CameraRollPreviewHeader.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 09.02.2022.
//

import UIKit

protocol CameraRollPreviewHeaderDelegate: AnyObject {

    func updateImagePreview(with image: UIImage)
    func didChangeContentMode(isAspectFit: Bool)

}

class CameraRollPreviewHeader: UICollectionReusableView {

    static let identifier = "CameraRollPreviewHeader"

    private var imagePreviewAspectFit: Bool = false

    weak var delegate: CameraRollPreviewHeaderDelegate?

    private let imagePreview: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
//        imageView.image = UIImage(named: "ZoogramCatLogo")
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .black
        return imageView
    }()

    private lazy var previewImageAspectButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "arrow.down.forward.and.arrow.up.backward"), for: .normal)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 15
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        button.addTarget(self, action: #selector(didTapAspectButton), for: .touchUpInside)
        return button
    }()

    public func update(with image: UIImage) {
        imagePreview.image = image
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        setupViewsAndConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViewsAndConstraints() {
        addSubviews(imagePreview, previewImageAspectButton)

        NSLayoutConstraint.activate([
            imagePreview.topAnchor.constraint(equalTo: self.topAnchor),
            imagePreview.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imagePreview.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            imagePreview.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            previewImageAspectButton.leadingAnchor.constraint(equalTo: imagePreview.leadingAnchor, constant: 15),
            previewImageAspectButton.bottomAnchor.constraint(equalTo: imagePreview.bottomAnchor, constant: -15),
            previewImageAspectButton.widthAnchor.constraint(equalToConstant: 30),
            previewImageAspectButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    @objc private func didTapAspectButton() {
        if imagePreviewAspectFit {
            imagePreview.contentMode = .scaleAspectFill
            imagePreview.setNeedsDisplay()
            previewImageAspectButton.setImage(UIImage(systemName: "arrow.down.forward.and.arrow.up.backward"), for: .normal)
        } else {
            imagePreview.contentMode = .scaleAspectFit
            imagePreview.setNeedsDisplay()
            previewImageAspectButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
        }
        imagePreviewAspectFit.toggle()
        delegate?.didChangeContentMode(isAspectFit: imagePreviewAspectFit)
    }

}
