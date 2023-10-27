//
//  PhotoPreviewCropView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 10.02.2023.
//

import UIKit

protocol CropViewDelegate: AnyObject {
    func didCropImage(_ image: UIImage?)
}

struct CropRatios {
    let square: CGFloat = 1/1
    let vertical: CGFloat = 4/5
}

class PhotoPreviewCropView: UIView {

    // MARK: - Internal Properties
    weak var delegate: CropViewDelegate?

    // MARK: - Private Properties
    private var cropView: UIView {
        return overlayView.cropView
    }

    private var isWidthDominant: Bool {
        let cropViewRatio = cropView.frame.size.width / cropView.frame.size.height
        return currentImageRatio < cropViewRatio
    }

    private var image: UIImage {
        didSet {
            updateImageView()
        }
    }
    private let cropRatio: CGFloat
    private var hasChangedAlignment: Bool = false {
        didSet {
            switchAspectButton()
        }
    }

    private let topView = UIView()
    private let imageView = UIImageView()
    private let overlayView: OverlayView

    private var currentImageRatio: CGFloat = 1

    private var imageCenterXConstraint: NSLayoutConstraint?
    private var imageCenterYConstraint: NSLayoutConstraint?
    private var imageWidthConstraint: NSLayoutConstraint?
    private var imageHeightConstraint: NSLayoutConstraint?
    private var imageTopConstraint: NSLayoutConstraint?
    private var imageLeadingConstraint: NSLayoutConstraint?
    private var imageBottomConstraint: NSLayoutConstraint?
    private var imageTrailingConstraint: NSLayoutConstraint?

    private var isTopEdgeAligned: Bool = true
    private var isBottomEdgeAligned: Bool = true
    private var isLeftEdgeAligned: Bool = true
    private var isRightEdgeAligned: Bool = true

    private var lastImageCenterXOffset: CGFloat = 0
    private var lastImageCenterYOffset: CGFloat = 0
    private var lastStoredImageWidth: CGFloat = 0
    private var lastStoredImageHeight: CGFloat = 0

    private var lastOverlayRect: CGSize = .zero

    private let cancelButtonCaption: String
    private let cropButtonCaption: String

    private lazy var previewImageAspectButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 15
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        button.addTarget(self, action: #selector(didTapAspectButton), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle
    convenience init(image: UIImage) {
        self.init(image: image, cancelButtonCaption: "Cancel", cropButtonCaption: "Crop")
    }

    init(image: UIImage, cancelButtonCaption: String, cropButtonCaption: String) {
        self.image = image
        self.cropRatio = CropRatios().square
        self.cancelButtonCaption = cancelButtonCaption
        self.cropButtonCaption = cropButtonCaption
        self.overlayView = OverlayView(cropRatio: cropRatio)
        super.init(frame: CGRect())
        loadView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func loadView() {

        self.backgroundColor = .systemBackground

        topView.clipsToBounds = true
        topView.translatesAutoresizingMaskIntoConstraints = false
        topView.backgroundColor = .black
        self.addSubview(topView)

        imageView.image = self.image
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        topView.addSubview(imageView)

        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        pinchGestureRecognizer.delegate = self
        topView.addGestureRecognizer(pinchGestureRecognizer)
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan))
        panGestureRecognizer.delegate = self
        imageView.addGestureRecognizer(panGestureRecognizer)

        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.isUserInteractionEnabled = false
        topView.addSubview(overlayView)
        topView.addSubview(previewImageAspectButton)

        let imageViewXCenterConstraint = imageView.centerXAnchor.constraint(equalTo: cropView.centerXAnchor)
        let imageViewYCenterConstraint = imageView.centerYAnchor.constraint(equalTo: cropView.centerYAnchor)
        imageViewXCenterConstraint.priority = .dragThatCanResizeScene
        imageViewYCenterConstraint.priority = .dragThatCanResizeScene

        NSLayoutConstraint.activate([
            topView.topAnchor.constraint(equalTo: self.topAnchor),
            topView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            topView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            topView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor),

            imageViewXCenterConstraint,
            imageViewYCenterConstraint,

            overlayView.topAnchor.constraint(equalTo: topView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: topView.leadingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: topView.bottomAnchor),
            overlayView.trailingAnchor.constraint(equalTo: topView.trailingAnchor),

            previewImageAspectButton.leadingAnchor.constraint(equalTo: topView.leadingAnchor, constant: 15),
            previewImageAspectButton.bottomAnchor.constraint(equalTo: topView.bottomAnchor, constant: -15),
            previewImageAspectButton.widthAnchor.constraint(equalToConstant: 30),
            previewImageAspectButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    func changeImage(image: UIImage) {
        self.image = image
    }

    private func updateImageView() {
        self.hasChangedAlignment = false
        imageView.image = image
        alignImage(shouldAlignByHeight: false)
    }

    // MARK: Align image method
    private func alignImage(shouldAlignByHeight: Bool) {
        guard cropView.frame != .zero else {
            return
        }

        var widthConstant: CGFloat
        var heightConstant: CGFloat
        let ratio = image.size.width / image.size.height

        if shouldAlignByHeight {
            widthConstant = cropView.frame.width
            heightConstant = cropView.frame.width / ratio
        } else {
            widthConstant = cropView.frame.height * ratio
            heightConstant = cropView.frame.height
        }

        resetConstraints()

        let imageCenterXConstraint = imageView.centerXAnchor.constraint(equalTo: cropView.centerXAnchor)
        imageCenterXConstraint.priority = .defaultHigh
        self.imageCenterXConstraint = imageCenterXConstraint

        let imageCenterYConstraint = imageView.centerYAnchor.constraint(equalTo: cropView.centerYAnchor)
        imageCenterYConstraint.priority = .defaultHigh
        self.imageCenterYConstraint = imageCenterYConstraint

        let imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: widthConstant)
        imageWidthConstraint.priority = .required
        self.imageWidthConstraint = imageWidthConstraint

        let imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: heightConstant)
        imageHeightConstraint.priority = .required
        self.imageHeightConstraint = imageHeightConstraint

        NSLayoutConstraint.activate([
            imageCenterXConstraint,
            imageCenterYConstraint,
            imageWidthConstraint,
            imageHeightConstraint
        ])

        self.currentImageRatio = ratio
        self.lastStoredImageWidth = imageWidthConstraint.constant
        self.lastStoredImageHeight = imageHeightConstraint.constant
    }

    private func resetConstraints() {
        imageCenterXConstraint?.isActive = false
        imageCenterXConstraint = nil

        imageCenterYConstraint?.isActive = false
        imageCenterYConstraint = nil

        imageWidthConstraint?.isActive = false
        imageWidthConstraint = nil

        imageHeightConstraint?.isActive = false
        imageHeightConstraint = nil
    }

    private func switchAspectButton() {
        if hasChangedAlignment {
            alignImage(shouldAlignByHeight: false)
            previewImageAspectButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"),
                                              for: .normal)
        } else {
            alignImage(shouldAlignByHeight: true)
            previewImageAspectButton.setImage(UIImage(systemName: "arrow.down.forward.and.arrow.up.backward"),
                                              for: .normal)
        }
    }

    @objc private func didTapAspectButton() {
        hasChangedAlignment.toggle()
    }

    // MARK: pinch method
    @objc private func pinch(_ pinch: UIPinchGestureRecognizer) {
        guard let imageWidthConstraint = imageWidthConstraint,
              let imageHeightConstraint = imageHeightConstraint else {
            return
        }

        if pinch.state == .began {
            lastStoredImageWidth = imageWidthConstraint.constant
            lastStoredImageHeight = imageHeightConstraint.constant
        }

        let scale = pinch.scale
        let ratio = currentImageRatio

        let maxWidth: CGFloat
        let maxHeight: CGFloat

        if isWidthDominant {
            maxWidth = cropView.frame.height * ratio
            maxHeight = cropView.frame.height

        } else {
            maxWidth = cropView.frame.width
            maxHeight = cropView.frame.width / ratio
        }

        let width = max(lastStoredImageWidth * scale, maxWidth)
        let height = max(lastStoredImageHeight * scale, maxHeight)

        self.imageWidthConstraint?.constant = width
        self.imageHeightConstraint?.constant = height

        checkIfImageViewOutOfBounds()

        if pinch.state == .ended {
            alignImageViewEdges {
//                imageView.isUserInteractionEnabled = false
                UIView.animate(withDuration: 0.4, delay: 0) {
                    self.layoutIfNeeded()
                } completion: { _ in
//                    self.imageView.isUserInteractionEnabled = true
                    self.isTopEdgeAligned = true
                    self.isBottomEdgeAligned = true
                    self.isLeftEdgeAligned = true
                    self.isRightEdgeAligned = true
                }
            }
        }
    }

    // MARK: pan method
    @objc private func pan(_ pan: UIPanGestureRecognizer) {
        guard let imageCenterXConstraint = imageCenterXConstraint,
              let imageCenterYConstraint = imageCenterYConstraint else {
            return
        }

        if pan.state == .began {
            lastImageCenterXOffset = imageCenterXConstraint.constant
            lastImageCenterYOffset = imageCenterYConstraint.constant
        }

        let trans = pan.translation(in: self)

        let centerX = lastImageCenterXOffset + trans.x
        let centerY = lastImageCenterYOffset + trans.y

        self.imageCenterXConstraint?.constant = centerX
        self.imageCenterYConstraint?.constant = centerY

        checkIfImageViewOutOfBounds()

        if pan.state == .ended {
            alignImageViewEdges {
//                imageView.isUserInteractionEnabled = false
                UIView.animate(withDuration: 0.4, delay: 0) {
                    self.layoutIfNeeded()
                } completion: { _ in
//                    self.imageView.isUserInteractionEnabled = true
                    self.isTopEdgeAligned = true
                    self.isBottomEdgeAligned = true
                    self.isLeftEdgeAligned = true
                    self.isRightEdgeAligned = true
                }

            }
        }
    }

    // MARK: Align edges method
    func alignImageViewEdges(completion: () -> Void) {
        guard let imageYCenter = self.imageCenterYConstraint?.constant,
              let imageXCenter = self.imageCenterXConstraint?.constant
        else {
            return
        }

        let leftBound = overlayView.frame.minX
        let rightBound = overlayView.frame.maxX
        let topBound = overlayView.frame.minY
        let bottomBound = overlayView.frame.maxY

        let imageLeftEdge = imageView.frame.minX
        let imageRightEdge = imageView.frame.maxX
        let imageTopEdge = imageView.frame.minY
        let imageBottomEdge = imageView.frame.maxY

        // Aligning by X to center
        if imageView.frame.width < overlayView.frame.width {
            print("Aligning by X to center")
            self.imageCenterXConstraint?.constant = 0
        } else {
            // Aligning left edge
            if isLeftEdgeAligned == false {
                let spaceToCompensate = leftBound + imageLeftEdge
                let centerXCoordinateWhenLeftIsAligned = imageXCenter - spaceToCompensate
                self.imageCenterXConstraint?.constant = centerXCoordinateWhenLeftIsAligned
            }
            // Aligning right edge
            if isRightEdgeAligned == false {
                let spaceToCompensate = rightBound - imageRightEdge
                let centerXCoordinateWhenRightIsAligned = imageXCenter + spaceToCompensate
                self.imageCenterXConstraint?.constant = centerXCoordinateWhenRightIsAligned
            }

        }
        // Aligning by Y to center
        if imageView.frame.height < overlayView.frame.height {
            self.imageCenterYConstraint?.constant = 0

        } else {
            // Aligning top edge
            if isTopEdgeAligned == false {
                let spaceToCompensate = topBound + imageTopEdge
                let centerYCoordinateWhenTopIsAligned = imageYCenter - spaceToCompensate
                self.imageCenterYConstraint?.constant = centerYCoordinateWhenTopIsAligned
            }
            // Aligning bottom edge
            if isBottomEdgeAligned == false {
                let spaceToCompensate = bottomBound - imageBottomEdge
                let centerYCoordinateWhenBottomIsAligned = imageYCenter + spaceToCompensate
                self.imageCenterYConstraint?.constant = centerYCoordinateWhenBottomIsAligned
            }
        }
        completion()
    }

    // MARK: Check bounds method
    func checkIfImageViewOutOfBounds() {
        let leftBound = overlayView.frame.minX
        let rightBound = overlayView.frame.maxX
        let topBound = overlayView.frame.minY
        let bottomBound = overlayView.frame.maxY

        let imageLeftEdge = imageView.frame.minX
        let imageRightEdge = imageView.frame.maxX
        let imageTopEdge = imageView.frame.minY
        let imageBottomEdge = imageView.frame.maxY

        if imageTopEdge > topBound {
            self.isTopEdgeAligned = false
        } else {
            self.isTopEdgeAligned = true
        }

        if imageBottomEdge < bottomBound {
            self.isBottomEdgeAligned = false
        } else {
            self.isBottomEdgeAligned = true
        }

        if imageLeftEdge > leftBound {
            self.isLeftEdgeAligned = false
        } else {
            self.isLeftEdgeAligned = true
        }

        if imageRightEdge < rightBound {
            self.isRightEdgeAligned = false
        } else {
            self.isRightEdgeAligned = true
        }
    }

    func makeCroppedImage() -> UIImage? {
        let imageSize = image.size
        let width = cropView.frame.width / imageView.frame.width
        let height = cropView.frame.height / imageView.frame.height
        let croppedCenterXCoordinate = (cropView.frame.origin.x - imageView.frame.origin.x) / imageView.frame.width
        let croppedCenterYCoordinate = (cropView.frame.origin.y - imageView.frame.origin.y) / imageView.frame.height

        let cropFrame = CGRect(x: croppedCenterXCoordinate * imageSize.width,
                               y: croppedCenterYCoordinate * imageSize.height,
                               width: imageSize.width * width,
                               height: imageSize.height * height)

        guard let cgImage = image.cgImage?.cropping(to: cropFrame) else {
            return nil
        }

        let cropImage = UIImage(cgImage: cgImage, scale: 1, orientation: .up)
        return cropImage
    }

}

extension PhotoPreviewCropView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view == otherGestureRecognizer.view {
            return true
        }
        return false
    }
}
