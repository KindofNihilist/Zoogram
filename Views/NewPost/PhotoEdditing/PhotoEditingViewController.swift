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
    private var currentEdditingViewKind: EdittingViewKind
    private var selectedPhotoEffectButton: EdditingFilterButton?

    private let photoFilters = PhotoFilters()
    private let editingFilters = EditingFilters()

    // MARK: CoreImage resources
    let originalImage: UIImage
    var modifiedImage: CIImage
    var autoEnhancedImage: CIImage?
    var currentFilter: ImageFilter!
    var edditingFiltersApplied = [FilterSubtype: FilterValue]()
    var photoFilterApplied = (filterType: FilterSubtype.normal, value: 0.0 as Float)
    // MARK: Metal resources

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: Subviews

    private lazy var metalView: ImageMetalPreview = {
        let metalView = ImageMetalPreview(image: self.originalImage)
        metalView.translatesAutoresizingMaskIntoConstraints = false
        metalView.clipsToBounds = true
        metalView.previewDelegate = self
        return metalView
    }()

    private lazy var photoEffectsView: EdditingFiltersView = {
        let scrollView = EdditingFiltersView(filters: self.editingFilters)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var photoFiltersView: PhotoFiltersView = {
        let scrollView = PhotoFiltersView(filters: self.photoFilters)
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
        self.currentEdditingViewKind = .edditingFilters
        currentFilter = PhotoFilters().withoutFilter
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

    private func setupNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.titleView = autoEnhanceButton
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: nextButton)
    }

    // MARK: Actions

    @objc private func navigateBack() {
        navigationController?.popViewController(animated: true)
    }

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
        guard var imageToEnhance = CIImage(image: self.originalImage), self.autoEnhancedImage == nil else {
            self.autoEnhancedImage = nil
            updateCurrentImage()
            animateAutoEnhanceButtonState(isApplied: false)
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
        animateAutoEnhanceButtonState(isApplied: true)
    }

    private func animateAutoEnhanceButtonState(isApplied: Bool) {
        var colorToApply: UIColor = isApplied ? UIColor.systemYellow : .white
        UIView.animate(withDuration: 0.2) {
            self.autoEnhanceButton.tintColor = colorToApply
        }
    }

    @objc private func didFinishEditingPhoto() {
        guard let edditedCIImage = applyFilters() else { return }
        let imageToPost = UIImage(ciImage: edditedCIImage)
        let makePostVC = MakeAPostViewController(photo: imageToPost)
        makePostVC.delegate = self.delegate
        navigationController?.pushViewController(makePostVC, animated: true)
    }

    func updateCurrentImage() {
        guard let imageToSet = applyFilters() else { return }
        self.modifiedImage = imageToSet
        self.metalView.setNeedsDisplay()
    }

    func applyFilters(shouldApplyImageFilter: Bool = true) -> CIImage? {
        print("applying filters")
        guard var inputImage = self.autoEnhancedImage ?? CIImage(image: originalImage) else { return nil }

        for filterType in edditingFiltersApplied {
            let filterToApply = editingFilters.getFilter(of: filterType.key)
            filterToApply.setInputImage(image: inputImage)
            filterToApply.applyFilter(sliderValue: filterType.value)
            inputImage = filterToApply.getOutput()!
        }

        if shouldApplyImageFilter {
            let imageFilter = photoFilters.getFilter(of: photoFilterApplied.filterType)
                    imageFilter.setInputImage(image: inputImage)
                    imageFilter.applyFilter(sliderValue: photoFilterApplied.value)
                    inputImage = imageFilter.getOutput()!
        }
        return inputImage
    }
}

// MARK: Filters delegate

extension PhotoEditingViewController: PhotoFiltersViewDelegate {

    func userHasSelected(button: EdditingFilterButton, with filter: PhotoFilter) {
        currentFilter = filter
        if button.hasBeenAlreadySelected {
            guard filter.filterSubtype != .normal else { return }
            сonfigureSlider(for: filter)
            showSlider()
        } else {
            photoFilterApplied.filterType = currentFilter.filterSubtype
            photoFilterApplied.value = currentFilter.latestValue
        }
    }
}

// MARK: Edditing effects delegate

extension PhotoEditingViewController: EddittingFiltersDelegate {

    func userHasSelected(button: EdditingFilterButton, with filter: ImageFilter) {
        self.selectedPhotoEffectButton = button
        currentFilter = filter
        edditingFiltersApplied[filter.filterSubtype] = filter.latestValue
        сonfigureSlider(for: filter)
        showSlider()
    }
}

// MARK: Slider Delegate

extension PhotoEditingViewController: PhotoEffectSliderDelegate {

    func didChangeSliderValue(value: Float) {
        if currentFilter.filterType == .editingFilter {
            edditingFiltersApplied[currentFilter.filterSubtype] = value
        } else if currentFilter.filterType == .photoFilter {
            photoFilterApplied.value = value
        }
        metalView.setNeedsDisplay()
        print("Slider value: \(value) for \(currentFilter.displayName)")
    }

    func cancelFilterApplication() {
        currentFilter.revertChanges()
        if currentFilter.filterType == .editingFilter {
            edditingFiltersApplied[currentFilter.filterSubtype] = currentFilter.latestValue
        } else if currentFilter.filterType == .photoFilter {
            photoFilterApplied.value = currentFilter.latestValue
        }
        metalView.setNeedsDisplay()
        hideSlider()
    }

    func saveFilterApplication() {
        guard let outputImage = applyFilters() else { return }
        let filterValue = sliderView.getSliderValue()
        if let currentFilter = currentFilter as? PhotoFilter {
            photoFilterApplied.filterType = currentFilter.filterSubtype
            photoFilterApplied.value = sliderView.getSliderValue()
        } else {
            selectedPhotoEffectButton?.hasAppliedRelatedEffect = filterValue != currentFilter.defaultValue
            if filterValue == currentFilter.defaultValue {
                edditingFiltersApplied.removeValue(forKey: currentFilter.filterSubtype)
            } else {
                edditingFiltersApplied[currentFilter.filterSubtype] = filterValue
            }
        }
        modifiedImage = outputImage
        currentFilter.latestValue = filterValue
        hideSlider()
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
        let isInverted = filter.filterSubtype == .warmth
        sliderView.configure(for: filter)
        sliderView.isInverted = isInverted
    }
}

extension PhotoEditingViewController: ImageMetalPreviewDelegate {
    func getImageToRender() -> CIImage? {
        return applyFilters()
    }
}
