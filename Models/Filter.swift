//
//  Filter.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 14.10.2022.
//

import UIKit

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
    case normal
    case noir
    case vivid
    case honey
    case silly
    case funky
    case paws
    case coldMonkey
}

@MainActor
protocol ImageFilter {
    var filterType: FilterType { get set }
    var minimumValue: Float { get set }
    var maximumValue: Float { get set }
    var defaultValue: Float { get set }
    var latestValue: Float { get set }
    var displayName: String { get set }
    func applyFilter(sliderValue: Float)
    func getOutput() -> CIImage?
    func revertChanges()
    func setInputImage(image: UIImage)
    func setInputImage(image: CIImage)
}

class Filter: ImageFilter {
    let filter: CIFilter
    let filterKey: String
    var filterType: FilterType
    var defaultValue: Float
    let filterName: String
    var displayName: String
    var filterIcon: UIImage
    var minimumValue: Float
    var maximumValue: Float
    var latestValue: Float

    init(filterType: FilterType, filterName: String, displayName: String, filterIcon: UIImage, filterKey: String, filterDefaultValue: Float, minimumValue: Float, maximumValue: Float) {
        self.filterType = filterType
        self.defaultValue = filterDefaultValue
        self.filter = CIFilter(name: filterName)!
        self.filterName = filterName
        self.displayName = displayName
        self.filterIcon = filterIcon
        self.filterKey = filterKey
        self.minimumValue = minimumValue
        self.maximumValue = maximumValue
        self.latestValue = filterDefaultValue

        if filterName == "CITemperatureAndTint" {
            self.filter.setValue(CIVector(x: 6500, y: 0), forKey: filterKey)
        } else {
            self.filter.setValue(filterDefaultValue, forKey: filterKey)
        }
    }

    func applyFilter(sliderValue: Float) {
        let filterValue = getFilterValue(for: sliderValue)
        filter.setValue(filterValue, forKey: filterKey)
    }

    func getOutput() -> CIImage? {
        guard let outputImage = self.filter.outputImage else {
            print("Returning nil instead of CIImage")
            return nil }
        return outputImage
    }

    func revertChanges() {
        applyFilter(sliderValue: latestValue)
    }

    private func getFilterValue(for sliderValue: Float) -> Any {
        print("sliderValue for \(self.filterType): ", sliderValue)
        switch filterType {
        case .warmth:
            return CIVector(x: CGFloat(sliderValue) + 6500, y: 0)
        case .tint:
            return CIVector(x: 6500, y: 0 + CGFloat(sliderValue))
        default:
            return NSNumber(value: sliderValue)
        }
    }

    func setInputImage(image: CIImage) {
        self.filter.setValue(image, forKey: kCIInputImageKey)
    }

    func setInputImage(image: UIImage) {
        let ciImage = CIImage(image: image)
        self.filter.setValue(ciImage, forKey: kCIInputImageKey)
    }

}

@MainActor
class PhotoFilter: ImageFilter {

    static let effects = EditingFilters()

    var displayName: String
    var filterType: FilterType
    var defaultValue: Float = 1.0
    var minimumValue: Float = 0.0
    var maximumValue: Float = 1.0
    var latestValue: Float = 1.0

    let overlayFilter = CIFilter(name: "CIColorMatrix")
    let compositionFilter = CIFilter(name: "CISourceOverCompositing")

    var inputImage: CIImage?
    var filteredImage: CIImage?
    var outputImage: CIImage?

    init(displayName: String, filterType: FilterType) {
        self.displayName = displayName
        self.filterType = filterType
    }

    func applyFilter() {
        fatalError("applyFilter method must be overriden and set filteredImage")
    }

    func applyFilter(sliderValue: Float) {
        changeFilterIntensity(to: sliderValue)
    }

    func getOutput() -> CIImage? {
        return outputImage
    }

    func revertChanges() {
        changeFilterIntensity(to: latestValue)
    }

    func setInputImage(image: UIImage) {
        self.inputImage = CIImage(image: image)
        applyFilter()
    }

    func setInputImage(image: CIImage) {
        self.inputImage = image
        applyFilter()
    }

    func getFilteredImage() -> UIImage? {
        guard let filteredImage = self.filteredImage else {
            print("GUARD FILTERED IMAGE")
            return nil
        }
        return UIImage(ciImage: filteredImage)
    }

    func getFilterPreview(for image: CIImage) -> UIImage? {
        setInputImage(image: image)
        guard let image = self.filteredImage else {
            return nil
        }
        self.outputImage = image
        return UIImage(ciImage: image)
    }

    func changeFilterIntensity(to alphaValue: Float) {
        let alphaValue = CGFloat(alphaValue)
        let overlayRGBA = [0, 0, 0, alphaValue]
        let alphaVector = CIVector(values: overlayRGBA, count: 4)
        overlayFilter?.setValue(filteredImage, forKey: kCIInputImageKey)
        overlayFilter?.setValue(alphaVector, forKey: "inputAVector")

        compositionFilter?.setValue(inputImage, forKey: kCIInputBackgroundImageKey)
        compositionFilter?.setValue(overlayFilter?.outputImage, forKey: kCIInputImageKey)
        self.outputImage = compositionFilter?.outputImage
    }
}

@MainActor
 func getFilter(of type: FilterType) -> ImageFilter {
    switch type {
    case .exposure:
        return EditingFilters().exposureFilter
    case .brightness:
        return EditingFilters().brightnessFilter
    case .contrast:
        return EditingFilters().contrastFilter
    case .saturation:
        return EditingFilters().saturationFilter
    case .warmth:
        return EditingFilters().warmthFilter
    case .tint:
        return EditingFilters().tintFilter
    case .highlihts:
        return EditingFilters().highlightsFilter
    case .shadows:
        return EditingFilters().shadowsFilter
    case .vignette:
        return EditingFilters().vignetteFilter
    case .noir:
        return ImageFilters().noirPhotoFilter
    case .vivid:
        return ImageFilters().vividPhotoFilter
    case .honey:
        return ImageFilters().honeyPhotoFilter
    case .silly:
        return ImageFilters().sillyPhotoFilter
    case .funky:
        return ImageFilters().funkyPhotoFilter
    case .paws:
        return ImageFilters().pawsPhotoFilter
    case .coldMonkey:
        return ImageFilters().coldMonkeyPhotoFilter
    case .normal:
        return ImageFilters().withoutFilter
    }
}
