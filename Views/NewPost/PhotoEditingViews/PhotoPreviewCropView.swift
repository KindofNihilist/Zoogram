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
    
    private let previewImageAspectButton: UIButton = {
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
            
            //            imageView.topAnchor.constraint(lessThanOrEqualTo: cropView.topAnchor),
            //            imageView.bottomAnchor.constraint(greaterThanOrEqualTo: cropView.bottomAnchor),
            //            imageView.leadingAnchor.constraint(lessThanOrEqualTo: cropView.leadingAnchor),
            //            imageView.trailingAnchor.constraint(greaterThanOrEqualTo: cropView.trailingAnchor),
            
            imageViewXCenterConstraint,
            imageViewYCenterConstraint,
            
            overlayView.topAnchor.constraint(equalTo: topView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: topView.leadingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: topView.bottomAnchor),
            overlayView.trailingAnchor.constraint(equalTo: topView.trailingAnchor),
            
            previewImageAspectButton.leadingAnchor.constraint(equalTo: topView.leadingAnchor, constant: 15),
            previewImageAspectButton.bottomAnchor.constraint(equalTo: topView.bottomAnchor, constant: -15),
            previewImageAspectButton.widthAnchor.constraint(equalToConstant: 30),
            previewImageAspectButton.heightAnchor.constraint(equalToConstant: 30),
        ])
    }
    
    //    override func viewDidLayoutSubviews() {
    //        super.viewDidLayoutSubviews()
    //
    //        if lastOverlayRect != overlayView.frame.size {
    //            updateImageView()
    //            lastOverlayRect = overlayView.frame.size
    //        }
    //    }
    
    func changeImage(image: UIImage) {
        self.image = image
    }
    
    private func updateImageView() {
        self.hasChangedAlignment = false
        imageView.image = image
        widthAlignImage()
    }
    //MARK: Align by width method
    private func widthAlignImage() {
        let ratio = image.size.width / image.size.height
        self.currentImageRatio = ratio
        
        imageCenterXConstraint?.isActive = false
        imageCenterXConstraint = nil
        let imageCenterXConstraint = imageView.centerXAnchor.constraint(equalTo: cropView.centerXAnchor)
        imageCenterXConstraint.priority = .defaultHigh
        self.imageCenterXConstraint = imageCenterXConstraint
        
        imageCenterYConstraint?.isActive = false
        imageCenterYConstraint = nil
        let imageCenterYConstraint = imageView.centerYAnchor.constraint(equalTo: cropView.centerYAnchor)
        imageCenterYConstraint.priority = .defaultHigh
        self.imageCenterYConstraint = imageCenterYConstraint
        
        guard cropView.frame != .zero else {
            return
        }
        
        let widthConstant = cropView.frame.height * ratio
        let heightConstant = cropView.frame.height
        
        imageWidthConstraint?.isActive = false
        imageWidthConstraint = nil
        let imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: widthConstant)
        imageWidthConstraint.priority = .required
        self.imageWidthConstraint = imageWidthConstraint
        
        imageHeightConstraint?.isActive = false
        imageHeightConstraint = nil
        let imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: heightConstant)
        imageHeightConstraint.priority = .required
        self.imageHeightConstraint = imageHeightConstraint
        
        NSLayoutConstraint.activate([
            imageCenterXConstraint,
            imageCenterYConstraint,
            imageWidthConstraint,
            imageHeightConstraint
        ])
        
        lastStoredImageWidth = imageWidthConstraint.constant
        lastStoredImageHeight = imageHeightConstraint.constant
    }
    //MARK: Align by height method
    private func heightAlignImage() {
        let ratio = image.size.width / image.size.height
        self.currentImageRatio = ratio
        
        imageCenterXConstraint?.isActive = false
        imageCenterXConstraint = nil
        let imageCenterXConstraint = imageView.centerXAnchor.constraint(equalTo: cropView.centerXAnchor)
        imageCenterXConstraint.priority = .defaultHigh
        self.imageCenterXConstraint = imageCenterXConstraint
        
        imageCenterYConstraint?.isActive = false
        imageCenterYConstraint = nil
        let imageCenterYConstraint = imageView.centerYAnchor.constraint(equalTo: cropView.centerYAnchor)
        imageCenterYConstraint.priority = .defaultHigh
        self.imageCenterYConstraint = imageCenterYConstraint
        
        guard cropView.frame != .zero else {
            return
        }
        
        let widthConstant = cropView.frame.width
        let heightConstant = cropView.frame.width / ratio
        
        imageWidthConstraint?.isActive = false
        imageWidthConstraint = nil
        let imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: widthConstant)
        imageWidthConstraint.priority = .required
        self.imageWidthConstraint = imageWidthConstraint
        
        imageHeightConstraint?.isActive = false
        imageHeightConstraint = nil
        let imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: heightConstant)
        imageHeightConstraint.priority = .required
        self.imageHeightConstraint = imageHeightConstraint
        
        NSLayoutConstraint.activate([
            imageCenterXConstraint,
            imageCenterYConstraint,
            imageWidthConstraint,
            imageHeightConstraint
        ])
        
        lastStoredImageWidth = imageWidthConstraint.constant
        lastStoredImageHeight = imageHeightConstraint.constant
    }
    
    private func switchAspectButton() {
        if hasChangedAlignment {
            widthAlignImage()
            previewImageAspectButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
        } else {
            heightAlignImage()
            previewImageAspectButton.setImage(UIImage(systemName: "arrow.down.forward.and.arrow.up.backward"), for: .normal)
        }
    }
    
    @objc private func didTapAspectButton() {
        hasChangedAlignment.toggle()
    }
    
    
    //MARK: pinch method
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
            
        }
        else {
            maxWidth = cropView.frame.width
            maxHeight = cropView.frame.width / ratio
        }
        
        let width = max(lastStoredImageWidth * scale, maxWidth)
        let height = max(lastStoredImageHeight * scale, maxHeight)
        
        self.imageWidthConstraint?.constant = width
        self.imageHeightConstraint?.constant = height
        
        checkIfImageViewOutOfBounds()
        
        if pinch.state == .ended {
            alignImageViewEdges() {
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
    
    
    //MARK: pan method
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
            alignImageViewEdges() {
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
    
    
    //MARK: Align edges method
    
    func alignImageViewEdges(completion: () -> Void) {
        guard let imageYCenter = self.imageCenterYConstraint?.constant,
              let imageXCenter = self.imageCenterXConstraint?.constant
        else {
            return
        }
        print("\n\n\n\nImage Y center: ", imageYCenter)
        print("Image X center: ", imageXCenter)
        print("\nIsLeftEdgeAligned: \(isLeftEdgeAligned) \nIsRightEdgeAligned \(isRightEdgeAligned) \nIsTopEdgeAligned \(isTopEdgeAligned) \nIsBottomEdgeAligned \(isBottomEdgeAligned)")
        
        let leftBound = overlayView.frame.minX
        let rightBound = overlayView.frame.maxX
        let topBound = overlayView.frame.minY
        let bottomBound = overlayView.frame.maxY
        print("\nBounds: ", leftBound, rightBound, topBound, bottomBound)
        
        let imageLeftEdge = imageView.frame.minX
        let imageRightEdge = imageView.frame.maxX
        let imageTopEdge = imageView.frame.minY
        let imageBottomEdge = imageView.frame.maxY
        print("\nImageView bounds: ", imageLeftEdge, imageRightEdge, imageTopEdge, imageBottomEdge)
        
        if imageView.frame.width < overlayView.frame.width {
            print("Aligning by X to center")
            self.imageCenterXConstraint?.constant = 0
        } else {
            
            if isLeftEdgeAligned == false {
                let spaceToCompensate = leftBound + imageLeftEdge
                let centerXCoordinateWhenLeftIsAligned = imageXCenter - spaceToCompensate
                print("\nAligning left edge")
                print("Space to compensate \(spaceToCompensate)")
                self.imageCenterXConstraint?.constant = centerXCoordinateWhenLeftIsAligned
            }
            
            if isRightEdgeAligned == false {
                let spaceToCompensate = rightBound - imageRightEdge
                let centerXCoordinateWhenRightIsAligned = imageXCenter + spaceToCompensate
                print("\nAligning right edge")
                print("Space to compensate \(spaceToCompensate)")
                self.imageCenterXConstraint?.constant = centerXCoordinateWhenRightIsAligned
            }
            
        }
        
        
        if imageView.frame.height < overlayView.frame.height {
            print("Aligning by Y to center")
            self.imageCenterYConstraint?.constant = 0
            
        } else {
            if isTopEdgeAligned == false {
                let spaceToCompensate = topBound + imageTopEdge
                let centerYCoordinateWhenTopIsAligned = imageYCenter - spaceToCompensate
                print("\nAligning top edge")
                print("Space to compensate \(spaceToCompensate)")
                self.imageCenterYConstraint?.constant = centerYCoordinateWhenTopIsAligned
            }
            
            if isBottomEdgeAligned == false {
                let spaceToCompensate = bottomBound - imageBottomEdge
                let centerYCoordinateWhenBottomIsAligned = imageYCenter + spaceToCompensate
                print("\nAligning bottom edge")
                print("Space to compensate \(spaceToCompensate)")
                self.imageCenterYConstraint?.constant = centerYCoordinateWhenBottomIsAligned
            }
            
        }
        
        completion()
    }
    
    
    //MARK: Check bounds method
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
//            print("Top edge out of bound")
        } else {
            self.isTopEdgeAligned = true
        }
        
        if imageBottomEdge < bottomBound {
            self.isBottomEdgeAligned = false
//            print("Bottom edge out of bound")
        } else {
            self.isBottomEdgeAligned = true
        }
        
        
        if imageLeftEdge > leftBound {
            self.isLeftEdgeAligned = false
//            print("Left edge out of bound")
        } else {
            self.isLeftEdgeAligned = true
        }
        
        if imageRightEdge < rightBound {
            self.isRightEdgeAligned = false
//            print("Right edge out of bound")
        } else {
            self.isRightEdgeAligned = true
        }
    }
    
    func makeCroppedImage() -> UIImage? {
        let imageSize = image.size
        let width = cropView.frame.width / imageView.frame.width
        let height = cropView.frame.height / imageView.frame.height
        let x = (cropView.frame.origin.x - imageView.frame.origin.x) / imageView.frame.width
        let y = (cropView.frame.origin.y - imageView.frame.origin.y) / imageView.frame.height
        
        let cropFrame = CGRect(x: x * imageSize.width,
                               y: y * imageSize.height,
                               width: imageSize.width * width,
                               height: imageSize.height * height)
        
        guard let cgImage = image.cgImage?.cropping(to: cropFrame) else {
            return nil
        }
        
        let cropImage = UIImage(cgImage: cgImage, scale: 1, orientation: .up)
        return cropImage
    }
    
}

private final class OverlayView: UIView {
    
    // MARK: - Internal Properties
    let cropView = UIView()
    
    // MARK: - Private Properties
    private let fadeView = UIView()
    
    private var overlayViewWidthConstraint: NSLayoutConstraint?
    private var overlayViewHeightConstraint: NSLayoutConstraint?
    
    // MARK: - Lifecycle
    init(cropRatio: CGFloat) {
        super.init(frame: .zero)
        
        fadeView.translatesAutoresizingMaskIntoConstraints = false
        fadeView.isUserInteractionEnabled = false
        addSubview(fadeView)
        
        cropView.backgroundColor = UIColor.clear
        cropView.isUserInteractionEnabled = false
        cropView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cropView)
        
        NSLayoutConstraint.activate([
            fadeView.leadingAnchor.constraint(equalTo: leadingAnchor),
            fadeView.centerXAnchor.constraint(equalTo: centerXAnchor),
            fadeView.centerYAnchor.constraint(equalTo: centerYAnchor),
            fadeView.topAnchor.constraint(equalTo: topAnchor),
            
            //            cropView.centerXAnchor.constraint(equalTo: centerXAnchor),
            //            cropView.centerYAnchor.constraint(equalTo: centerYAnchor)
            
            cropView.topAnchor.constraint(equalTo: self.topAnchor),
            cropView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            cropView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            cropView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
        
        //        updateCropRatio(cropRatio)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard overlayViewWidthConstraint == nil,
              overlayViewHeightConstraint == nil else {
            return
        }
        
        overlayViewWidthConstraint = widthAnchor.constraint(equalToConstant: frame.width)
        overlayViewWidthConstraint?.priority = .defaultHigh
        overlayViewWidthConstraint?.isActive = true
        
        overlayViewHeightConstraint = heightAnchor.constraint(equalToConstant: frame.height)
        overlayViewHeightConstraint?.priority = .defaultHigh
        overlayViewHeightConstraint?.isActive = true
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
