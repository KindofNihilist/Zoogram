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
}

class Filter {
    let filter: CIFilter
    let filterKey: String
    let filterType: FilterType
    var defaultValue: Any
    let filterName: String
    let minimumValue: Float
    let maximumValue: Float
    
    init(filterType: FilterType, filterName: String, filterKey: String, filterDefaultValue: Any, minimumValue: Float, maximumValue: Float) {
        self.filterType = filterType
        self.defaultValue = filterDefaultValue
        self.filter = CIFilter(name: filterName)!
        self.filterName = filterName
        self.filterKey = filterKey
        self.minimumValue = minimumValue
        self.maximumValue = maximumValue
        
        if filterName == "CITemperatureAndTint" {
            self.filter.setValue(CIVector(x: 6500, y: 0), forKey: filterKey)
        } else {
            self.filter.setValue(filterDefaultValue, forKey: filterKey)
        }
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
