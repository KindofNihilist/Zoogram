//
//  PhotoEditing.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 13.02.2022.
//

import UIKit
import MetalKit

class PhotoEditingViewController: UIViewController {
    
    let isWidthDominant: Bool
    let ratio: CGFloat
    var hasPrintedImageData: Bool = false
    
    //MARK: CoreImage resources
    let originalImage: UIImage
    var modifiedImage: UIImage
    var context: CIContext!
    var ciImage: CIImage!
    var currentFilter: Filter!
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    
    //MARK: Metal resources
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var sourceTexture: MTLTexture!
    var filterValue: Any = 0
    
    var appliedFilters = [Filter]()
    
    
    //MARK: Filters
    let exposureFilter = Filter(filterType: .exposure, filterName: "CIExposureAdjust", filterKey: kCIInputEVKey, filterDefaultValue: 0.0 as Float, minimumValue: -1.0, maximumValue: 1.0)
    
    let brightnessFilter = Filter(filterType: .brightness, filterName: "CIColorControls", filterKey: kCIInputBrightnessKey, filterDefaultValue: 0 as Float, minimumValue: -0.15, maximumValue: 0.15)
    
    let contrastFilter = Filter(filterType: .contrast, filterName: "CIColorControls", filterKey: kCIInputContrastKey, filterDefaultValue: 1 as Float, minimumValue: 0.8, maximumValue: 1.2)
    
    let saturationFilter = Filter(filterType: .saturation, filterName: "CIColorControls", filterKey: kCIInputSaturationKey, filterDefaultValue: 1 as Float, minimumValue: 0, maximumValue: 2)
    
    let warmthFilter = Filter(filterType: .warmth, filterName: "CITemperatureAndTint", filterKey: "inputTargetNeutral", filterDefaultValue: CIVector(x: 6500, y: 0), minimumValue: -3000, maximumValue: 3000)
    
    let tintFilter = Filter(filterType: .tint, filterName: "CITemperatureAndTint", filterKey: "inputTargetNeutral", filterDefaultValue: CIVector(x: 6500, y: 0), minimumValue: -100, maximumValue: 100)
    
    let highlightsFilter = Filter(filterType: .highlihts, filterName: "CIHighlightShadowAdjust", filterKey: "inputHighlightAmount", filterDefaultValue: 1 as Float, minimumValue: 0, maximumValue: 2)
    
    let shadowsFilter = Filter(filterType: .shadows, filterName: "CIHighlightShadowAdjust", filterKey: "inputShadowAmount", filterDefaultValue: 0 as Float, minimumValue: -1, maximumValue: 2)
    
    let vignetteFilter = Filter(filterType: .vignette, filterName: "CIVignette", filterKey: "inputIntensity", filterDefaultValue: 0 as Float, minimumValue: 0, maximumValue: 2)
    
    
    //MARK: Subviews
    private var metalView: MTKView = {
        let metalView = MTKView()
        metalView.translatesAutoresizingMaskIntoConstraints = false
        metalView.clipsToBounds = true
        return metalView
    }()
    
    
    private let photoEditingPreview: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let editingOptionsHorizontalScrollView: PhotoEffectsHorizontalScrollView = {
        let scrollView = PhotoEffectsHorizontalScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    init(photo: UIImage, isWidthDominant: Bool, ratio: CGFloat) {
        self.originalImage = photo
        self.modifiedImage = photo
        self.isWidthDominant = isWidthDominant
        print("Is width dominant", isWidthDominant)
        self.ratio = ratio
        photoEditingPreview.image = photo
        currentFilter = Filter(filterType: .exposure, filterName: "CIExposureAdjust", filterKey: kCIInputEVKey,  filterDefaultValue: 0, minimumValue: 0, maximumValue: 0)
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
        editingOptionsHorizontalScrollView.delegate = self
        print("Loaded photo editing view")
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    private func setupMetalPreview() {
        guard let imageData = originalImage.pngData() else {
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
        
        self.metalView.clearColor = MTLClearColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1)
    }
    
    private func setupNavBar() {
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(navigateBack))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(didFinishEditingPhoto))
        navigationItem.leftBarButtonItem?.tintColor = .white
        let button = UIButton()
        button.setImage(UIImage(systemName: "wand.and.stars"), for: .normal)
        button.tintColor = .white
        navigationItem.titleView = button
    }
    
    private func setupViewsAndConstraints() {
        view.addSubviews(metalView, editingOptionsHorizontalScrollView)
        let viewHeight = view.frame.size.height
        NSLayoutConstraint.activate([
            metalView.widthAnchor.constraint(equalTo: view.widthAnchor),
            metalView.heightAnchor.constraint(equalToConstant: viewHeight / 2),
            metalView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            metalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            
            editingOptionsHorizontalScrollView.topAnchor.constraint(equalTo: metalView.bottomAnchor),
            editingOptionsHorizontalScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            editingOptionsHorizontalScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            editingOptionsHorizontalScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
    
    private func userHasSelectedFilter(filter: Filter?, filterName: String, filterDefaultValue: Any, sliderMinimumValue: Float, sliderMaximumValue: Float) {
        guard let filter = filter else { return }
        currentFilter = filter
        var isInverted = false
        var sliderDefaultValue: Float = 0
        
        switch filter.filterType {
        case .warmth:
            isInverted = true
            sliderDefaultValue = 0
        case .tint:
            sliderDefaultValue = 0
        default:
            sliderDefaultValue = filterDefaultValue as! Float
        }
        
        filterValue = filterDefaultValue
        
        let sliderView = PhotoEffectSliderView(sliderDefaultValue: sliderDefaultValue, sliderMaximumValue: sliderMaximumValue, sliderMinimumValue: sliderMinimumValue, effectName: filterName, key: kCIInputEVKey, isInverted: isInverted)
        sliderView.isHidden = true
        sliderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sliderView)
        sliderView.topAnchor.constraint(equalTo: metalView.bottomAnchor).isActive = true
        sliderView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        sliderView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        sliderView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        sliderView.alpha = 0
        sliderView.delegate = self
        
        
        print("Created slider")
        
        UIView.animate(withDuration: 0.3) {
            self.editingOptionsHorizontalScrollView.alpha = 0
            self.editingOptionsHorizontalScrollView.isHidden = true
            sliderView.isHidden = false
            sliderView.alpha = 1
        }
    }
    
    private func hideSelectedFilter(view: UIView) {
        UIView.animate(withDuration: 0.2) {
            view.alpha = 0
            view.isHidden = false
            self.editingOptionsHorizontalScrollView.isHidden = false
            self.editingOptionsHorizontalScrollView.alpha = 1
        } completion: { _ in
            view.removeFromSuperview()
        }
    }
    
    @objc private func navigateBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func didFinishEditingPhoto() {
        navigationController?.pushViewController(MakeAPostViewController(photo: self.modifiedImage), animated: true)
    }
}

extension PhotoEditingViewController: PhotoEffectsHorizontalScrollViewDelegate, PhotoEffectSliderDelegate {
    
    //MARK: Initializing selected filters
    
    func showExposureSlider() {
        exposureFilter.setInputImage(image: modifiedImage)
        userHasSelectedFilter(filter: exposureFilter, filterName: "Exposure", filterDefaultValue: exposureFilter.defaultValue, sliderMinimumValue: exposureFilter.minimumValue, sliderMaximumValue: exposureFilter.maximumValue)
    }
    
    func showBrightnessSlider() {
        brightnessFilter.setInputImage(image: modifiedImage)
        userHasSelectedFilter(filter: brightnessFilter, filterName: "Brightness", filterDefaultValue: brightnessFilter.defaultValue, sliderMinimumValue: brightnessFilter.minimumValue, sliderMaximumValue: brightnessFilter.maximumValue)
    }
    
    func showContrastSlider() {
        contrastFilter.setInputImage(image: modifiedImage)
        userHasSelectedFilter(filter: contrastFilter, filterName: "Contrast", filterDefaultValue: contrastFilter.defaultValue, sliderMinimumValue: contrastFilter.minimumValue, sliderMaximumValue: contrastFilter.maximumValue)
    }
    
    func showSaturationSlider() {
        saturationFilter.setInputImage(image: modifiedImage)
        userHasSelectedFilter(filter: saturationFilter, filterName: "Saturation", filterDefaultValue: saturationFilter.defaultValue, sliderMinimumValue: saturationFilter.minimumValue, sliderMaximumValue: saturationFilter.maximumValue)
    }
    
    func showWarmthSlider() {
        warmthFilter.setInputImage(image: modifiedImage)
        userHasSelectedFilter(filter: warmthFilter, filterName: "Warmth", filterDefaultValue: warmthFilter.defaultValue, sliderMinimumValue: warmthFilter.minimumValue, sliderMaximumValue: warmthFilter.maximumValue)
    }
    
    func showTintSlider() {
        tintFilter.setInputImage(image: modifiedImage)
        userHasSelectedFilter(filter: tintFilter, filterName: "Tint", filterDefaultValue: tintFilter.defaultValue, sliderMinimumValue: tintFilter.minimumValue, sliderMaximumValue: tintFilter.maximumValue)
    }
    
    func showHighlightsSlider() {
        highlightsFilter.setInputImage(image: modifiedImage)
        userHasSelectedFilter(filter: highlightsFilter, filterName: "Highlights", filterDefaultValue: highlightsFilter.defaultValue, sliderMinimumValue: highlightsFilter.minimumValue, sliderMaximumValue: highlightsFilter.maximumValue)
    }
    
    func showShadowsSlider() {
        shadowsFilter.setInputImage(image: modifiedImage)
        userHasSelectedFilter(filter: shadowsFilter, filterName: "Shadows", filterDefaultValue: shadowsFilter.defaultValue, sliderMinimumValue: shadowsFilter.minimumValue, sliderMaximumValue: shadowsFilter.maximumValue)
    }
    
    func showVignetteSlider() {
        vignetteFilter.setInputImage(image: modifiedImage)
        userHasSelectedFilter(filter: vignetteFilter, filterName: "Vignette", filterDefaultValue: vignetteFilter.defaultValue, sliderMinimumValue: vignetteFilter.minimumValue, sliderMaximumValue: vignetteFilter.maximumValue)
    }
    
    
    //MARK: Cancel/Save actions
    func cancelFilterApplication(view: UIView) {
        currentFilter.revertChanges()
        filterValue = currentFilter.defaultValue
        hideSelectedFilter(view: view)
    }
    
    func saveFilterApplication(view: UIView) {
        guard let outputImage = currentFilter.getOutput(), let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
        modifiedImage = UIImage(cgImage: cgImage)
        appliedFilters.append(currentFilter)
        hideSelectedFilter(view: view)
        
        switch currentFilter.filterType {
        case .exposure:
            exposureFilter.defaultValue = self.filterValue
        case .brightness:
            brightnessFilter.defaultValue = self.filterValue
        case .contrast:
            contrastFilter.defaultValue = self.filterValue
        case .saturation:
            saturationFilter.defaultValue = self.filterValue
        case .warmth:
            warmthFilter.defaultValue = self.filterValue
        case .tint:
            tintFilter.defaultValue = self.filterValue
        case .highlihts:
            highlightsFilter.defaultValue = self.filterValue
        case .shadows:
            shadowsFilter.defaultValue = self.filterValue
        case .vignette:
            vignetteFilter.defaultValue = self.filterValue
        }
    }
    
    
    func didChangeSliderValue(value: Float) {
        //        print("Slider value: \(value)")
        
        
        switch currentFilter.filterType {
            
        case .warmth:
            self.filterValue = CIVector(x: CGFloat(value) + 6500, y: 0)
//            print(filterValue)
        case .tint:
            self.filterValue = CIVector(x: 6500, y: 0 + CGFloat(value))
        default:
            self.filterValue = NSNumber(value: value)
        }
    }
}

extension PhotoEditingViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        guard let currentDrawable = view.currentDrawable,
              let sourceTexture = self.sourceTexture,
              let commandBuffer = self.commandQueue.makeCommandBuffer(),
              let inputImage = CIImage(mtlTexture: sourceTexture),
              let currentFilter = self.currentFilter else { return }
        
        currentFilter.applyFilter(value: self.filterValue)
        
        
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
        
        if !hasPrintedImageData {
            print("Bounds width: \(bounds.width)")
            print("Bounds height: \(bounds.height) \n")
            print("inputImage height\(inputImage.extent.height)")
            print("inputImage width: \(inputImage.extent.width) \n")
            print("Scaled image height: \(height)")
            print("Scaled image width: \(width) \n")
            print("Mid X point: \(bounds.midX) \n")
            print("Calculated X origin point: \(imageOriginXPoint)")
            print("Calculated Y origin point: \(imageOriginYPoint) \n")
            hasPrintedImageData = true
        }
        
        if let filterOutput = currentFilter.getOutput() {
            var scaledImage = filterOutput
            
#if targetEnvironment(simulator)
            scaledImage = scaledImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale)).transformed(by: CGAffineTransform(translationX: originX, y: originY < 0 ? 0 : originY))
#else
            scaledImage = scaledImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale)).transformed(by: CGAffineTransform(translationX: originX < 0 ? 0 : originX, y: originY < 0 ? 0 : originY))
#endif
            
            
            context.render(scaledImage, to: currentDrawable.texture, commandBuffer: commandBuffer, bounds: bounds, colorSpace: colorSpace)
            
            commandBuffer.present(currentDrawable)
            commandBuffer.commit()
        }
        
    }
}
