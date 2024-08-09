//
//  PhotoPreviewCropView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 10.02.2023.
//

import UIKit

enum AspectButtonState {
    case expanded
    case contracted

    func switchedState() -> AspectButtonState {
        if self == .contracted {
            return .expanded
        } else {
            return .contracted
        }
    }
}

enum AligningSide {
    case width
    case height
}

@MainActor class ViewConstraints {
    var centerXConstraint = NSLayoutConstraint()
    var centerYConstraint = NSLayoutConstraint()
    var widthConstraint = NSLayoutConstraint()
    var heightConstraint = NSLayoutConstraint()
    var topConstraint = NSLayoutConstraint()
    var leadingConstraint = NSLayoutConstraint()
    var bottomConstraint = NSLayoutConstraint()
    var trailingConstraint = NSLayoutConstraint()
}

class AlignmentStates {
    var isTopEdgeAligned: Bool = true
    var isBottomEdgeAligned: Bool = true
    var isLeftEdgeAligned: Bool = true
    var isRightEdgeAligned: Bool = true
}

class PhotoPreviewCropView: UIView {

    private var imageConstraints = ViewConstraints()
    private var alignmentStates = AlignmentStates()
    private var currentImageRatio: CGFloat = 1
    private var lastImageOffset: CGPoint = CGPoint(x: 0, y: 0)
    private var lastStoredImageSize: CGSize = CGSize(width: 0, height: 0)
    private var lastOverlayRect: CGSize = .zero
    private var lastPinchCenter: CGPoint = CGPoint(x: 0, y: 0)
    private let cropButtonCaption: String
    private var isBeingZoomed: Bool = false

    private var isWidthDominant: Bool {
        let cropViewRatio = cropView.frame.size.width / cropView.frame.size.height
        return currentImageRatio < cropViewRatio
    }

    private var image: UIImage {
        didSet {
            updateImageView()
        }
    }

    private var aspectButtonState: AspectButtonState = .contracted {
        didSet {
            self.switchAspectButton()
        }
    }

    private let topView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
    }()
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.preferredImageDynamicRange = .high
        return imageView
    }()

    private let overlayView: OverlayView = {
        let overlayView = OverlayView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.isUserInteractionEnabled = false
        return overlayView
    }()
    
    private var cropView: UIView {
        return overlayView.cropView
    }

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
        self.init(image: image, cropButtonCaption: "Crop")
    }

    init(image: UIImage, cropButtonCaption: String) {
        self.image = image
        self.cropButtonCaption = cropButtonCaption
        super.init(frame: CGRect())
        setupView()
        setupGestureRecognizers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.addSubview(topView)
        topView.addSubviews(imageView, overlayView, previewImageAspectButton)
        imageView.image = self.image

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

    private func setupGestureRecognizers() {
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        pinchGestureRecognizer.delegate = self
        imageView.addGestureRecognizer(pinchGestureRecognizer)
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan))
        panGestureRecognizer.delegate = self
        imageView.addGestureRecognizer(panGestureRecognizer)
    }

    func changeImage(image: UIImage) {
        self.image = image
    }

    private func updateImageView() {
        imageView.image = image
        self.currentImageRatio = image.ratio()
        self.aspectButtonState = .contracted
        alignImage(aligningState: .contracted, animated: false)
    }

    private func getSmallestDimension() -> AligningSide {
        image.size.width > image.size.height ? .height : .width
    }

    private func getContractedImageSize(using smallestAligningSide: AligningSide) -> CGSize {
        var widthConstant: CGFloat
        var heightConstant: CGFloat
        let ratio = currentImageRatio

        switch smallestAligningSide {
        case .height:
            widthConstant = cropView.frame.width
            heightConstant = cropView.frame.width / ratio
        case .width:
            widthConstant = cropView.frame.height * ratio
            heightConstant = cropView.frame.height
        }
        return CGSize(width: widthConstant, height: heightConstant)
    }

    private func getExpandedImageSize(using smallestAligningSide: AligningSide) -> CGSize {
        var widthConstant: CGFloat
        var heightConstant: CGFloat
        let ratio = currentImageRatio

        switch smallestAligningSide {
        case .height:
            widthConstant = cropView.frame.height * ratio
            heightConstant = cropView.frame.height
        case .width:
            widthConstant = cropView.frame.width
            heightConstant = cropView.frame.width / ratio
        }
        return CGSize(width: widthConstant, height: heightConstant)
    }

    // MARK: Align image method
    private func alignImage(aligningState: AspectButtonState, animated: Bool) {
        guard cropView.frame != .zero else {
            return
        }
        let smallestDimension = getSmallestDimension()
        var imageSize: CGSize

        switch aligningState {
        case .contracted:
            imageSize = getContractedImageSize(using: smallestDimension)
        case .expanded:
            imageSize = getExpandedImageSize(using: smallestDimension)
        }

        resetConstraints()

        self.imageConstraints.centerXConstraint = imageView.centerXAnchor.constraint(equalTo: cropView.centerXAnchor)
        self.imageConstraints.centerXConstraint.priority = .defaultHigh
        self.imageConstraints.centerYConstraint = imageView.centerYAnchor.constraint(equalTo: cropView.centerYAnchor)
        self.imageConstraints.centerYConstraint.priority = .defaultHigh

        self.imageConstraints.widthConstraint = imageView.widthAnchor.constraint(equalToConstant: imageSize.width)
        self.imageConstraints.widthConstraint.priority = .required
        self.imageConstraints.heightConstraint = imageView.heightAnchor.constraint(equalToConstant: imageSize.height)
        self.imageConstraints.heightConstraint.priority = .required

        self.lastStoredImageSize.width = self.imageConstraints.widthConstraint.constant
        self.lastStoredImageSize.height = self.imageConstraints.heightConstraint.constant

        NSLayoutConstraint.activate([
            imageConstraints.centerXConstraint,
            imageConstraints.centerYConstraint,
            imageConstraints.widthConstraint,
            imageConstraints.heightConstraint
        ])

        if animated {
            UIView.animate(withDuration: 0.3) {
                self.layoutIfNeeded()
            }
        }
    }

    private func resetConstraints() {
        imageConstraints.centerXConstraint.deactivate()
        imageConstraints.centerYConstraint.deactivate()
        imageConstraints.heightConstraint.deactivate()
        imageConstraints.widthConstraint.deactivate()
    }

    private func switchAspectButton() {
        switch aspectButtonState {
        case .expanded:
            let expandedStateImage = UIImage(systemName: "arrow.down.forward.and.arrow.up.backward")
            previewImageAspectButton.setImage(expandedStateImage, for: .normal)
        case .contracted:
            let contractedStateImage = UIImage(systemName: "arrow.up.left.and.arrow.down.right")
            previewImageAspectButton.setImage(contractedStateImage, for: .normal)
        }
    }

    @objc private func didTapAspectButton() {
        aspectButtonState = aspectButtonState.switchedState()
        alignImage(aligningState: aspectButtonState, animated: true)
    }

    // MARK: pinch method

    @objc private func pinch(_ pinch: UIPinchGestureRecognizer) {
        guard let imageView = pinch.view else { return }

        if pinch.state == .ended || pinch.state == .cancelled || pinch.state == .failed {
            isBeingZoomed = false
            alignImageViewEdges {
                UIView.animate(withDuration: 0.4, delay: 0) {
                    self.layoutIfNeeded()
                } completion: { _ in
                    self.alignmentStates.isTopEdgeAligned = true
                    self.alignmentStates.isBottomEdgeAligned = true
                    self.alignmentStates.isLeftEdgeAligned = true
                    self.alignmentStates.isRightEdgeAligned = true
                }
            }
        }

        guard pinch.numberOfTouches >= 2 else {
            return
        }
        isBeingZoomed = true
        lastStoredImageSize.width = imageConstraints.widthConstraint.constant
        lastStoredImageSize.height = imageConstraints.heightConstraint.constant
        lastImageOffset.x = imageConstraints.centerXConstraint.constant
        lastImageOffset.y = imageConstraints.centerYConstraint.constant

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

        let width = max(lastStoredImageSize.width * scale, maxWidth)
        let height = max(lastStoredImageSize.height * scale, maxHeight)
        imageConstraints.widthConstraint.constant = width
        imageConstraints.heightConstraint.constant = height

        let pinchCenter = pinch.location(in: imageView)
        let deltaX = (pinchCenter.x - imageView.bounds.midX) * (1 - scale)
        let deltaY = (pinchCenter.y - imageView.bounds.midY) * (1 - scale)
        let centerX = lastImageOffset.x + deltaX
        let centerY = lastImageOffset.y + deltaY
        imageConstraints.centerXConstraint.constant = centerX
        imageConstraints.centerYConstraint.constant = centerY

        checkIfImageViewOutOfBounds()
        pinch.scale = 1
    }

    // MARK: pan method
    @objc private func pan(_ pan: UIPanGestureRecognizer) {
        if pan.state == .began {
            lastImageOffset.x = imageConstraints.centerXConstraint.constant
            lastImageOffset.y = imageConstraints.centerYConstraint.constant
        }

        let trans = pan.translation(in: self)
        let centerX = lastImageOffset.x + trans.x
        let centerY = lastImageOffset.y + trans.y
        if isBeingZoomed {
            // scale new coordinates properly according to zoom value
        }
        imageConstraints.centerXConstraint.constant = centerX
        imageConstraints.centerYConstraint.constant = centerY

        checkIfImageViewOutOfBounds()

        if pan.state == .ended || pan.state == .failed || pan.state == .cancelled {
            alignImageViewEdges {
                UIView.animate(withDuration: 0.4, delay: 0) {
                    self.layoutIfNeeded()
                } completion: { _ in
                    self.alignmentStates.isTopEdgeAligned = true
                    self.alignmentStates.isBottomEdgeAligned = true
                    self.alignmentStates.isLeftEdgeAligned = true
                    self.alignmentStates.isRightEdgeAligned = true
                }
            }
        }
    }

    // MARK: Align edges method
    func alignImageViewEdges(completion: () -> Void) {
        let imageYCenter = imageConstraints.centerYConstraint.constant
        let imageXCenter = imageConstraints.centerXConstraint.constant

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
            imageConstraints.centerXConstraint.constant = 0
        } else {
            // Aligning left edge
            if alignmentStates.isLeftEdgeAligned == false {
                let spaceToCompensate = leftBound + imageLeftEdge
                let centerXCoordinateWhenLeftIsAligned = imageXCenter - spaceToCompensate
                imageConstraints.centerXConstraint.constant = centerXCoordinateWhenLeftIsAligned
            }
            // Aligning right edge
            if alignmentStates.isRightEdgeAligned == false {
                let spaceToCompensate = rightBound - imageRightEdge
                let centerXCoordinateWhenRightIsAligned = imageXCenter + spaceToCompensate
                imageConstraints.centerXConstraint.constant = centerXCoordinateWhenRightIsAligned
            }
        }
        // Aligning by Y to center
        if imageView.frame.height < overlayView.frame.height {
            imageConstraints.centerYConstraint.constant = 0

        } else {
            // Aligning top edge
            if alignmentStates.isTopEdgeAligned == false {
                let spaceToCompensate = topBound + imageTopEdge
                let centerYCoordinateWhenTopIsAligned = imageYCenter - spaceToCompensate
                imageConstraints.centerYConstraint.constant = centerYCoordinateWhenTopIsAligned
            }
            // Aligning bottom edge
            if alignmentStates.isBottomEdgeAligned == false {
                let spaceToCompensate = bottomBound - imageBottomEdge
                let centerYCoordinateWhenBottomIsAligned = imageYCenter + spaceToCompensate
                imageConstraints.centerYConstraint.constant = centerYCoordinateWhenBottomIsAligned
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

        self.alignmentStates.isTopEdgeAligned = imageTopEdge < topBound
        self.alignmentStates.isBottomEdgeAligned = imageBottomEdge > bottomBound
        self.alignmentStates.isLeftEdgeAligned = imageLeftEdge < leftBound
        self.alignmentStates.isRightEdgeAligned = imageRightEdge > rightBound
    }

    func getCroppedImage() -> UIImage {
        let imageSize = image.size
        var widthRatio: CGFloat = 1
        var heightRatio: CGFloat = 1
        var croppedCenterXCoordinate: CGFloat = (imageView.frame.origin.x / imageView.frame.width).rounded(.down)
        var croppedCenterYCoordinate: CGFloat = (imageView.frame.origin.y / imageView.frame.height).rounded(.down)

        if imageView.frame.width > cropView.frame.width {
            widthRatio = cropView.frame.width / imageView.frame.width
            let xDifference = (cropView.frame.origin.x - imageView.frame.origin.x)
            croppedCenterXCoordinate = ((xDifference / imageView.frame.width) * imageSize.width).rounded(.down)
        }
        if imageView.frame.height > cropView.frame.height {
            heightRatio = cropView.frame.height / imageView.frame.height
            let yDifference = (cropView.frame.origin.y - imageView.frame.origin.y)
            croppedCenterYCoordinate = ((yDifference / imageView.frame.height) * imageSize.height).rounded(.down)
        }

        let imageWidth = (imageSize.width * widthRatio).rounded(.down)
        let imageHeight = (imageSize.height * heightRatio).rounded(.down)

        let cropFrame = CGRect(
            x: croppedCenterXCoordinate,
            y: croppedCenterYCoordinate,
            width: imageWidth,
            height: imageHeight)

        let croppedImage = image.croppedInRect(rect: cropFrame)
        return croppedImage
    }
}

extension PhotoPreviewCropView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view == imageView && otherGestureRecognizer.view == imageView {
            return false
        }
        return false
    }
}
