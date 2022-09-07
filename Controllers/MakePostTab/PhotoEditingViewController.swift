//
//  PhotoEditing.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 13.02.2022.
//

import UIKit
import MetalKit

enum FilterType {
    case exposure
    case brightness
    case contrast
    case saturation
    case warmth
    case tint
    case highlihts
    case shadows
    case vignette
}

class Filter {
    private let filter: CIFilter
    private let filterKey: String
    fileprivate let filterType: FilterType
    fileprivate var defaultValue: Any
    fileprivate let filterName: String
    fileprivate let minimumValue: Float
    fileprivate let maximumValue: Float
    
    init(filterType: FilterType, filterName: String, filterKey: String, filterDefaultValue: Any, minimumValue: Float, maximumValue: Float) {
        self.filterType = filterType
        self.defaultValue = filterDefaultValue
        self.filter = CIFilter(name: filterName)!
        self.filterName = filterName
        self.filter.setValue(filterDefaultValue, forKey: filterKey)
        self.filterKey = filterKey
        self.minimumValue = minimumValue
        self.maximumValue = maximumValue
    }
    
    func applyFilter(value: Any) {
        filter.setValue(value, forKey: filterKey)
    }
    
    func getOutput() -> CIImage? {
        guard let outputImage = self.filter.outputImage else { return nil }
        return outputImage
    }
    
    func revertChanges() {
        filter.setValue(defaultValue, forKey: filterKey)
    }
    
    func setInputImage(image: UIImage) {
        let ciImage = CIImage(image: image)
        self.filter.setValue(ciImage, forKey: kCIInputImageKey)
    }
}


class PhotoEditingViewController: UIViewController {
    
    private var isAspectFit: Bool
    
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
    var sliderValue: Any = 0
    
    var appliedFilters = [Filter]()
    
    
    //MARK: Filters
    let exposureFilter = Filter(filterType: .exposure, filterName: "CIExposureAdjust", filterKey: kCIInputEVKey, filterDefaultValue: 0, minimumValue: -1, maximumValue: 1)
    let brightnessFilter = Filter(filterType: .brightness, filterName: "CIColorControls", filterKey: kCIInputBrightnessKey, filterDefaultValue: 0, minimumValue: -0.15, maximumValue: 0.15)
    let contrastFilter = Filter(filterType: .contrast, filterName: "CIColorControls", filterKey: kCIInputContrastKey, filterDefaultValue: 1, minimumValue: 0.8, maximumValue: 1.2)
    let saturationFilter = Filter(filterType: .saturation, filterName: "CIColorControls", filterKey: kCIInputSaturationKey, filterDefaultValue: 1, minimumValue: 0, maximumValue: 2)
    let warmthFilter = Filter(filterType: .warmth, filterName: "CITemperatureAndTint", filterKey: "inputTargetNeutral", filterDefaultValue: CIVector(x: 6500, y: 0), minimumValue: -3000, maximumValue: 3000)
    let tintFilter = Filter(filterType: .tint, filterName: "CITemperatureAndTint", filterKey: "inputTargetNeutral", filterDefaultValue: CIVector(x: 6500, y: 0), minimumValue: -100, maximumValue: 100)
    let highlightsFilter = Filter(filterType: .highlihts, filterName: "CIHighlightShadowAdjust", filterKey: "inputHighlightAmount", filterDefaultValue: 1, minimumValue: 0, maximumValue: 2)
    let shadowsFilter = Filter(filterType: .shadows, filterName: "CIHighlightShadowAdjust", filterKey: "inputShadowAmount", filterDefaultValue: 0, minimumValue: -1, maximumValue: 2)
    let vignetteFilter = Filter(filterType: .vignette, filterName: "CIVignette", filterKey: "inputIntensity", filterDefaultValue: 0, minimumValue: 0, maximumValue: 2)
    
    
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
    
    private let editingOptionsHorizontalScrollView: PhotoEditingHorizontalScrollView = {
        let scrollView = PhotoEditingHorizontalScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    init(photo: UIImage, isAspectFit: Bool) {
        self.originalImage = photo
        self.modifiedImage = photo
        self.isAspectFit = isAspectFit
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
    
    private func setupMetalPreview() {
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        
        metalView.delegate = self
        metalView.device = device
        metalView.framebufferOnly = false
        
        context = CIContext(mtlDevice: device)
        
        let loader = MTKTextureLoader(device: device)
        
        #if targetEnvironment(simulator)
        sourceTexture = try! loader.newTexture(cgImage: originalImage.cgImage!, options: [MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.flippedVertically])
        #else
        sourceTexture = try! loader.newTexture(cgImage: originalImage.cgImage!, options: [:])
        #endif
        
        self.metalView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1)
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
        
        NSLayoutConstraint.activate([
            metalView.widthAnchor.constraint(equalTo: view.widthAnchor),
            metalView.heightAnchor.constraint(equalTo: view.widthAnchor),
            metalView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            metalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            
            editingOptionsHorizontalScrollView.topAnchor.constraint(equalTo: metalView.bottomAnchor),
            editingOptionsHorizontalScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            editingOptionsHorizontalScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            editingOptionsHorizontalScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
    
    private func userHasSelectedFilter(filter: Filter?, filterName: String, sliderDefaultValue: Any, sliderMinimumValue: Float, sliderMaximumValue: Float) {
        guard let filter = filter else { return }
        currentFilter = filter
        var isInverted = false
        sliderValue = sliderDefaultValue
//        if metalView == nil {
//            view.addSubview(metalRenderingView)
//            metalRenderingView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
//            metalRenderingView.heightAnchor.constraint(equalTo: view.widthAnchor).isActive = true
//            metalRenderingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
//            metalRenderingView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
//        }
        let sliderView = PhotoEffectSliderView(sliderDefaultValue: sliderDefaultValue as! Float, sliderMaximumValue: sliderMaximumValue, sliderMinimumValue: sliderMinimumValue, effectName: filterName, key: kCIInputEVKey, isInverted: isInverted)
        sliderView.isHidden = true
        sliderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sliderView)
        sliderView.topAnchor.constraint(equalTo: metalView.bottomAnchor).isActive = true
        sliderView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        sliderView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        sliderView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        sliderView.alpha = 0
        sliderView.delegate = self
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
        
    }
}

extension PhotoEditingViewController: PhotoEditingHorizontalScrollViewDelegate, PhotoEffectSliderDelegate {
    
    //MARK: Initializing selected filters
    
    func showExposureSlider() {
        exposureFilter.setInputImage(image: modifiedImage)
        userHasSelectedFilter(filter: exposureFilter, filterName: "Exposure", sliderDefaultValue: exposureFilter.defaultValue, sliderMinimumValue: exposureFilter.minimumValue, sliderMaximumValue: exposureFilter.maximumValue)
    }
    
    func showBrightnessSlider() {
        brightnessFilter.setInputImage(image: modifiedImage)
        userHasSelectedFilter(filter: brightnessFilter, filterName: "Brightness", sliderDefaultValue: brightnessFilter.defaultValue, sliderMinimumValue: brightnessFilter.minimumValue, sliderMaximumValue: brightnessFilter.maximumValue)
    }
    
    func showContrastSlider() {
        contrastFilter.setInputImage(image: modifiedImage)
        userHasSelectedFilter(filter: contrastFilter, filterName: "Contrast", sliderDefaultValue: contrastFilter.defaultValue, sliderMinimumValue: contrastFilter.minimumValue, sliderMaximumValue: contrastFilter.maximumValue)
    }
    
    func showSaturationSlider() {
        saturationFilter.setInputImage(image: modifiedImage)
        userHasSelectedFilter(filter: saturationFilter, filterName: "Saturation", sliderDefaultValue: saturationFilter.defaultValue, sliderMinimumValue: saturationFilter.minimumValue, sliderMaximumValue: saturationFilter.maximumValue)
    }
    
    func showWarmthSlider() {
        warmthFilter.setInputImage(image: modifiedImage)
        userHasSelectedFilter(filter: warmthFilter, filterName: "Warmth", sliderDefaultValue: warmthFilter.defaultValue, sliderMinimumValue: warmthFilter.minimumValue, sliderMaximumValue: warmthFilter.maximumValue)
    }
    
    func showTintSlider() {
        tintFilter.setInputImage(image: modifiedImage)
        userHasSelectedFilter(filter: tintFilter, filterName: "Tint", sliderDefaultValue: tintFilter.defaultValue, sliderMinimumValue: tintFilter.minimumValue, sliderMaximumValue: tintFilter.maximumValue)
    }
    
    func showHighlightsSlider() {
        highlightsFilter.setInputImage(image: modifiedImage)
        userHasSelectedFilter(filter: highlightsFilter, filterName: "Highlights", sliderDefaultValue: highlightsFilter.defaultValue, sliderMinimumValue: highlightsFilter.minimumValue, sliderMaximumValue: highlightsFilter.maximumValue)
    }
    
    func showShadowsSlider() {
        shadowsFilter.setInputImage(image: modifiedImage)
        userHasSelectedFilter(filter: shadowsFilter, filterName: "Shadows", sliderDefaultValue: shadowsFilter.defaultValue, sliderMinimumValue: shadowsFilter.minimumValue, sliderMaximumValue: shadowsFilter.maximumValue)
    }
    
    func showVignetteSlider() {
        vignetteFilter.setInputImage(image: modifiedImage)
        userHasSelectedFilter(filter: vignetteFilter, filterName: "Vignette", sliderDefaultValue: vignetteFilter.defaultValue, sliderMinimumValue: vignetteFilter.minimumValue, sliderMaximumValue: vignetteFilter.maximumValue)
    }
    
    
    //MARK: Cancel/Save actions
    func cancelFilterApplication(view: UIView) {
        currentFilter.revertChanges()
        sliderValue = currentFilter.defaultValue
        hideSelectedFilter(view: view)
    }
    
    func saveFilterApplication(view: UIView) {
        guard let outputImage = currentFilter.getOutput(), let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
        modifiedImage = UIImage(cgImage: cgImage)
        appliedFilters.append(currentFilter)
        hideSelectedFilter(view: view)
        
        switch currentFilter.filterType {
        case .exposure:
            exposureFilter.defaultValue = self.sliderValue
        case .brightness:
            brightnessFilter.defaultValue = self.sliderValue
        case .contrast:
            contrastFilter.defaultValue = self.sliderValue
        case .saturation:
            saturationFilter.defaultValue = self.sliderValue
        case .warmth:
            warmthFilter.defaultValue = self.sliderValue
        case .tint:
            tintFilter.defaultValue = self.sliderValue
        case .highlihts:
            highlightsFilter.defaultValue = self.sliderValue
        case .shadows:
            shadowsFilter.defaultValue = self.sliderValue
        case .vignette:
            vignetteFilter.defaultValue = self.sliderValue
        }
    }
    
    
    func didChangeSliderValue(value: Float) {
        print("Slider value: \(value)")
        if currentFilter.filterName == "CITemperatureAndTint" {
            self.sliderValue = CIVector(x: CGFloat(value) + 6500, y: 0)
        } else {
            self.sliderValue = NSNumber(value: value)
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
        
        currentFilter.applyFilter(value: self.sliderValue)
        
        let bounds = CGRect(x: 0, y: 0, width: view.drawableSize.width, height: view.drawableSize.height)
        
        let scaleX = view.drawableSize.width / inputImage.extent.width
        let scaleY = view.drawableSize.height / inputImage.extent.height
        var scale: CGFloat = 0
        if isAspectFit {
            scale = (scaleY > scaleX) ? scaleX : scaleY
        } else {
            scale = (scaleY > scaleX) ? scaleY : scaleX
        }
    
        let width = inputImage.extent.width * scale
        let height = inputImage.extent.height * scale
        let originX = (bounds.width - width) / 2
        let originY = (bounds.height - height) / 2
        
        if let filterOutput = currentFilter.getOutput() {
            var scaledImage = filterOutput
            #if targetEnvironment(simulator)
            scaledImage = scaledImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale)).transformed(by: CGAffineTransform(translationX: originX < 0 ? 0 : originX, y: originY < 0 ? 0 : originY))
            #else
            scaledImage = scaledImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale)).transformed(by: CGAffineTransform(translationX: originX < 0 ? 0 : originX, y: originY < 0 ? 0 : originY))
            #endif
            
            
            context.render(scaledImage, to: currentDrawable.texture, commandBuffer: commandBuffer, bounds: bounds, colorSpace: colorSpace)
            
            commandBuffer.present(currentDrawable)
            commandBuffer.commit()
        }
        
    }
}
