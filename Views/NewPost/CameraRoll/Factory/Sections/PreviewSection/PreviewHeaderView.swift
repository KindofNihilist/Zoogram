//
//  CameraRollHeader.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 09.02.2022.
//

import UIKit

class PreviewHeaderView: UICollectionReusableView {

    static var identifier: String {
        return String(describing: self)
    }
    
    var previewCropView: PhotoPreviewCropView = {
        let previewView = PhotoPreviewCropView(image: UIImage())
        previewView.translatesAutoresizingMaskIntoConstraints = false
        return previewView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = .black
        setupPreview()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPreview() {
        addSubview(previewCropView)
        NSLayoutConstraint.activate([
            previewCropView.topAnchor.constraint(equalTo: self.topAnchor),
            previewCropView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            previewCropView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            previewCropView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
    
    func updatePreview(with image: UIImage?) {
        guard let image = image else {
            return
        }
        previewCropView.changeImage(image: image)
    }
    
    func getPreviewImage() -> UIImage {
        previewCropView.getCroppedImage()
    }
}
