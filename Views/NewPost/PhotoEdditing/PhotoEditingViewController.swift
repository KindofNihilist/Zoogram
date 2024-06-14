//
//  PhotoEditing.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 13.02.2022.
//

import UIKit
import MetalKit

enum EdittingViewKind {
    case edditingFilters
    case imageFilters
}

typealias FilterValue = Float

class PhotoEditingViewController: UIViewController {

    weak var delegate: NewPostProtocol?

    let isWidthDominant: Bool
    let ratio: CGFloat
    private var currentEdditingViewKind: EdittingViewKind
    private var selectedPhotoEffectButton: EdditingFilterButton?
    private var selectedPhotoFilterButton: EdditingFilterButton?

    // MARK: CoreImage resources
    let originalImage: UIImage
    var modifiedImage: CIImage
    var autoEnhancedImage: CIImage?
    var context: CIContext!
    var currentFilter: ImageFilter!
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    var edditingFiltersApplied = [FilterType: FilterValue]()
    var imageFilterApplied = (filterType: FilterType.normal, value: 0.0 as Float)
    // MARK: Metal resources
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var sourceTexture: MTLTexture!

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: Subviews

    private var metalView: MTKView = {
        let metalView = MTKView()
        metalView.translatesAutoresizingMaskIntoConstraints = false
        metalView.clipsToBounds = true
        return metalView
    }()

    private let photoEffectsView: PhotoEffectsView = {
        let scrollView = PhotoEffectsView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let photoFiltersView: PhotoFiltersView = {
        let scrollView = PhotoFiltersView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alpha = 0
        scrollView.isHidden = true
        return scrollView
    }()

    private lazy var sliderView: FilterValueSliderView = {
        let slider = FilterValueSliderView()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.delegate = self
        slider.alpha = 0
        slider.isHidden = true
        return slider
    }()

    private lazy var filterButton: UIButton = {
        let button = UIButton()
        let title = String(localized: "Filter")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setTitleColor(.darkGray, for: .normal)
        button.titleLabel?.font = CustomFonts.boldFont(ofSize: 16)
        button.addTarget(self, action: #selector(didSelectFiltersTab), for: .touchUpInside)
        return button
    }()

    private lazy var editButton: UIButton = {
        let button = UIButton()
        let title = String(localized: "Edit")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = CustomFonts.boldFont(ofSize: 16)
        button.addTarget(self, action: #selector(didSelectEditTab), for: .touchUpInside)
        return button
    }()

    private lazy var backButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 30).isActive = true
        let config = UIImage.SymbolConfiguration(pointSize: 21)
        button.setImage(UIImage(systemName: "chevron.backward", withConfiguration: config), for: .normal)
        button.addTarget(self, action: #selector(navigateBack), for: .touchUpInside)
        button.tintColor = .white
        button.contentHorizontalAlignment = .left
        return button

    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 30).isActive = true
        let title = String(localized: "Next")
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(didFinishEditingPhoto), for: .touchUpInside)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = CustomFonts.boldFont(ofSize: 17)
        return button
    }()

    private lazy var autoEnhanceButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
        button.setImage(UIImage(systemName: "wand.and.stars"), for: .normal)
        button.addTarget(self, action: #selector(autoEnhanceImage), for: .touchUpInside)
        button.tintColor = .white
        return button
    }()

    // MARK: Initialization
    init(photo: UIImage) {
        self.originalImage = photo
        self.modifiedImage = CIImage(cgImage: photo.cgImage!)
        self.isWidthDominant = photo.isWidthDominant()
        self.currentEdditingViewKind = .edditingFilters
        self.ratio = photo.ratio()
        currentFilter = ImageFilters().withoutFilter
        currentFilter.setInputImage(image: photo)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        view.backgroundColor = .black
        setupNavBar()
        setupViewsAndConstraints()
        setupMetalPreview()
        photoEffectsView.delegate = self
        photoFiltersView.delegate = self
        photoFiltersView.setupFilterPreviews(for: self.modifiedImage)
    }

    // MARK: Constraints setup
    private func setupViewsAndConstraints() {
        view.addSubviews(metalView, photoEffectsView, photoFiltersView, sliderView, filterButton, editButton)
        NSLayoutConstraint.activate([
            metalView.widthAnchor.constraint(equalTo: view.widthAnchor),
            metalView.heightAnchor.constraint(equalTo: view.widthAnchor),
            metalView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            metalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            photoEffectsView.topAnchor.constraint(equalTo: metalView.bottomAnchor),
            photoEffectsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            photoEffectsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            photoEffectsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            photoFiltersView.topAnchor.constraint(equalTo: metalView.bottomAnchor),
            photoFiltersView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            photoFiltersView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            photoFiltersView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            sliderView.topAnchor.constraint(equalTo: metalView.bottomAnchor),
            sliderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sliderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sliderView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            filterButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterButton.trailingAnchor.constraint(equalTo: view.centerXAnchor),
            filterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            filterButton.heightAnchor.constraint(equalToConstant: 40),

            editButton.leadingAnchor.constraint(equalTo: view.centerXAnchor),
            editButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            editButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            editButton.heightAnchor.constraint(equalTo: filterButton.heightAnchor)
        ])
    }

    private func setupMetalPreview() {
        guard let imageData = originalImage.jpegData(compressionQuality: 1) else {
            print("Couldn't convert chosen image to Data")
            return
        }
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        metalView.delegate = self
        metalView.device = device
        metalView.framebufferOnly = false
        context = CIContext(mtlDevice: device)

        let loader = MTKTextureLoader(device: device)

        do {
            sourceTexture = try loader.newTexture(data: imageData)
        } catch {
            print("Couldn't create a texture with chosen image")
        }
    }

    private func setupNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.titleView = autoEnhanceButton
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: nextButton)
    }

    // MARK: Actions
    @objc private func didSelectFiltersTab() {
        self.filterButton.isUserInteractionEnabled = false
        self.editButton.isUserInteractionEnabled = false
        self.photoFiltersView.isHidden = false
        UIView.animateKeyframes(withDuration: 0.2, delay: 0) {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.6) {
                self.photoEffectsView.alpha = 0
                self.filterButton.setTitleColor(.white, for: .normal)
                self.editButton.setTitleColor(.darkGray, for: .normal)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.4) {
                self.photoFiltersView.alpha = 1
            }
        } completion: { _ in
            self.currentEdditingViewKind = .imageFilters
            self.editButton.isUserInteractionEnabled = true
            self.photoEffectsView.isHidden = true
        }
    }

    @objc private func didSelectEditTab() {
        self.photoEffectsView.isHidden = false
        self.filterButton.isUserInteractionEnabled = false
        self.editButton.isUserInteractionEnabled = false
        UIView.animateKeyframes(withDuration: 0.2, delay: 0) {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.6) {
                self.filterButton.setTitleColor(.darkGray, for: .normal)
                self.editButton.setTitleColor(.white, for: .normal)
                self.photoFiltersView.alpha = 0
            }
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.4) {
                self.photoEffectsView.alpha = 1
            }
        } completion: { _ in
            self.currentEdditingViewKind = .edditingFilters
            self.filterButton.isUserInteractionEnabled = true
            self.photoFiltersView.isHidden = true
        }
    }

    @objc private func autoEnhanceImage() {
        guard var imageToEnhance = CIImage(image: self.originalImage), self.autoEnhancedImage == nil
        else {
            self.autoEnhancedImage = nil
            updateCurrentImage()
            return
        }
        let enhancementFilters = imageToEnhance.autoAdjustmentFilters()
        for filter in enhancementFilters {
            filter.setValue(imageToEnhance, forKey: kCIInputImageKey)
            if let outputImage = filter.outputImage {
                imageToEnhance = outputImage
            }
        }
        self.autoEnhancedImage = imageToEnhance
        updateCurrentImage()
    }

    @objc private func navigateBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func didFinishEditingPhoto() {
        let imageToPost = UIImage(ciImage: self.modifiedImage)
        let makePostVC = MakeAPostViewController(photo: imageToPost)
        makePostVC.delegate = self.delegate
        navigationController?.pushViewController(makePostVC, animated: true)
    }

    func updateCurrentImage() {
        guard let imageToSet = getImageForEdditing(for: currentFilter) else { return }
        self.modifiedImage = imageToSet
        self.currentFilter.setInputImage(image: imageToSet)
        self.currentFilter.applyFilter(sliderValue: currentFilter.latestValue)

    }

    func getImageForEdditing(for selectedFilter: ImageFilter?, shouldApplyImageFilter: Bool = true) -> CIImage? {
        guard var inputImage = self.autoEnhancedImage ?? CIImage(image: originalImage) else { return nil }

        for filterType in edditingFiltersApplied {
            if filterType.key == selectedFilter?.filterType {
                continue
            }
            let filterToApply = getFilter(of: filterType.key)
            filterToApply.setInputImage(image: inputImage)
            filterToApply.applyFilter(sliderValue: filterType.value)
            inputImage = filterToApply.getOutput()!
        }
        return inputImage
    }
}

// MARK: Filters delegate

extension PhotoEditingViewController: PhotoFiltersViewDelegate {

    func userHasSelected(button: EdditingFilterButton, with filter: PhotoFilter) {
        guard let imageForEdditing = getImageForEdditing(for: filter) else { return }

        filter.setInputImage(image: imageForEdditing)
        currentFilter = filter
        currentFilter.applyFilter(sliderValue: currentFilter.latestValue)

        if button.hasBeenAlreadySelected {
            guard filter.filterType != .normal else { return }
            сonfigureSlider(for: filter)
            showSlider()
        } else {
            self.selectedPhotoFilterButton?.hasAppliedRelatedEffect = false
            self.selectedPhotoFilterButton?.hasBeenAlreadySelected = false
            self.selectedPhotoFilterButton = button
            self.selectedPhotoFilterButton?.hasAppliedRelatedEffect = true
            self.selectedPhotoFilterButton?.hasBeenAlreadySelected = true
            self.imageFilterApplied.filterType = currentFilter.filterType
            self.imageFilterApplied.value = currentFilter.latestValue
            self.modifiedImage = currentFilter.getOutput()!
        }
    }
}

// MARK: Edditing effects delegate

extension PhotoEditingViewController: PhotoEffectsViewDelegate {

    func userHasSelected(button: EdditingFilterButton, with filter: ImageFilter) {
        guard let imageForEdditing = getImageForEdditing(for: filter) else { return }
        self.selectedPhotoEffectButton = button
        filter.setInputImage(image: imageForEdditing)
        currentFilter = filter
        сonfigureSlider(for: filter)
        showSlider()
    }
}

// MARK: Slider Delegate

extension PhotoEditingViewController: PhotoEffectSliderDelegate {

    func didChangeSliderValue(value: Float) {
        currentFilter.applyFilter(sliderValue: value)
        print("Slider value: \(value) for \(currentFilter.displayName)")
    }

    func cancelFilterApplication() {
        currentFilter.revertChanges()
        hideSlider()
    }

    func saveFilterApplication() {
        guard let outputImage = currentFilter.getOutput() else { return }
        let filterValue = sliderView.getSliderValue()
        if let currentFilter = currentFilter as? PhotoFilter {
            imageFilterApplied.filterType = currentFilter.filterType
            imageFilterApplied.value = sliderView.getSliderValue()
        } else {
            selectedPhotoEffectButton?.hasAppliedRelatedEffect = filterValue != currentFilter.defaultValue
            edditingFiltersApplied[currentFilter.filterType] = filterValue
        }
        modifiedImage = outputImage
        currentFilter.latestValue = filterValue
        hideSlider()
//        print("FINAL Slider value: \(currentFilter.latestValue) for \(currentFilter.displayName)")
        print("APPLIED FILTERS LIST: \(edditingFiltersApplied)")
//        currentFilter.defaultValue = self.filterValue
    }

    private func showSlider() {
        let viewToHide = currentEdditingViewKind == .edditingFilters ? self.photoEffectsView : self.photoFiltersView
        self.sliderView.isHidden = false

        UIView.animate(withDuration: 0.3) {
            viewToHide.alpha = 0
            self.backButton.alpha = 0
            self.autoEnhanceButton.alpha = 0
            self.nextButton.alpha = 0
            self.editButton.alpha = 0
            self.filterButton.alpha = 0
            self.sliderView.alpha = 1
        } completion: { _ in
            viewToHide.isHidden = true
            self.editButton.isHidden = true
            self.filterButton.isHidden = true
        }
    }

    private func hideSlider() {
        let viewToShow = currentEdditingViewKind == .edditingFilters ? self.photoEffectsView : self.photoFiltersView
        self.backButton.alpha = 1
        self.autoEnhanceButton.alpha = 1
        self.nextButton.alpha = 1
        self.editButton.isHidden = false
        self.filterButton.isHidden = false
        self.photoFiltersView.isHidden = false
        viewToShow.isHidden = false

        UIView.animate(withDuration: 0.2) {
            self.sliderView.alpha = 0
            self.editButton.alpha = 1
            self.filterButton.alpha = 1
            viewToShow.alpha = 1
        } completion: { _ in
            self.sliderView.isHidden = true
        }
    }

    private func сonfigureSlider(for filter: ImageFilter) {
        let isInverted = filter.filterType == .warmth
        sliderView.configure(for: filter)
        sliderView.isInverted = isInverted
    }
}

// MARK: MTKViewDelegate

extension PhotoEditingViewController: MTKViewDelegate {
    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func createScaledImage(image: CIImage, originY: CGFloat, originX: CGFloat, scale: CGFloat) -> CIImage {
#if targetEnvironment(simulator)
            let originY = originY < 0 ? 0 : originY
            let transformedPosition = CGAffineTransform(translationX: originX, y: originY)
            let transformedScale = CGAffineTransform(scaleX: scale, y: scale)
            return image
                .transformed(by: transformedScale)
                .transformed(by: transformedPosition)
#else
            let originY = originY < 0 ? 0 : originY
            let originX = originX < 0 ? 0 : originX
            let transformedPosition = CGAffineTransform(translationX: originX, y: originY)
            let transformedScale = CGAffineTransform(scaleX: scale, y: scale)
            return image
                .transformed(by: transformedScale)
                .transformed(by: transformedPosition)
#endif
    }

    // MetalKit was not updated for concurrency yet, so it might throw warnings.
    // Using nonisolated to silence the warning is not an option since there are MainActor isolated properties used inside
    // and the MainActor.assumeIsolated is only available in iOS 17.0+
    func draw(in view: MTKView) {
        guard let currentDrawable = view.currentDrawable,
              let sourceTexture = self.sourceTexture,
              let commandBuffer = self.commandQueue.makeCommandBuffer(),
              let inputImage = CIImage(mtlTexture: sourceTexture),
              let currentFilter = self.currentFilter else { return }

        let bounds = CGRect(x: 0, y: 0, width: view.drawableSize.width, height: view.drawableSize.height)

        let scaleX = view.drawableSize.width / inputImage.extent.width
        let scaleY = view.drawableSize.height / inputImage.extent.height
        var scale: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0
        var imageOriginYPoint: CGFloat = 0
        var imageOriginXPoint: CGFloat = 0

        scale = (scaleY > scaleX) ? scaleX : scaleY

        width = inputImage.extent.width * scale
        height = inputImage.extent.height * scale

        if isWidthDominant {
            imageOriginYPoint = (bounds.maxY - height) / 2
        } else {
            imageOriginXPoint = (bounds.maxX - width) / 2
        }

        let originX = (bounds.minX + imageOriginXPoint)
        let originY = (bounds.minY + imageOriginYPoint)

        if let filterOutput = currentFilter.getOutput() {

            let scaledImage = createScaledImage(image: filterOutput,
                                                originY: originY,
                                                originX: originX,
                                                scale: scale)

            context.render(scaledImage,
                           to: currentDrawable.texture,
                           commandBuffer: commandBuffer,
                           bounds: bounds,
                           colorSpace: colorSpace)

            commandBuffer.present(currentDrawable)
            commandBuffer.commit()
        }
    }
}
