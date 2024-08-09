//
//  EditingEffects.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 21.11.2023.
//

import UIKit.UIImage

@MainActor
class EditingFilters {

    lazy var allFilters = [self.exposureFilter,
                           self.brightnessFilter,
                           self.contrastFilter,
                           self.saturationFilter,
                           self.warmthFilter,
                           self.tintFilter,
                           self.highlightsFilter,
                           self.shadowsFilter,
                           self.vignetteFilter]

    func getFilter(of type: FilterSubtype) -> ImageFilter {
        switch type {
        case .exposure:
            return self.exposureFilter
        case .brightness:
            return self.brightnessFilter
        case .contrast:
            return self.contrastFilter
        case .saturation:
            return self.saturationFilter
        case .warmth:
            return self.warmthFilter
        case .tint:
            return self.tintFilter
        case .highlihts:
            return self.highlightsFilter
        case .shadows:
            return self.shadowsFilter
        case .vignette:
            return self.vignetteFilter
        default:
            fatalError()
        }
    }

    lazy var exposureFilter = Filter(
        filterType: .editingFilter,
        filterSubtype: .exposure,
        filterName: "CIExposureAdjust",
        displayName: String(localized: "Exposure"),
        filterIcon: UIImage(systemName: "plusminus")!,
        filterKey: kCIInputEVKey,
        filterDefaultValue: 0.0,
        minimumValue: -1.0,
        maximumValue: 1.0)

    lazy var brightnessFilter = Filter(
        filterType: .editingFilter,
        filterSubtype: .brightness,
        filterName: "CIColorControls",
        displayName: String(localized: "Brightness"),
        filterIcon: UIImage(systemName: "sun.max")!,
        filterKey: kCIInputBrightnessKey,
        filterDefaultValue: 0.0,
        minimumValue: -0.10,
        maximumValue: 0.10)

    lazy var contrastFilter = Filter(
        filterType: .editingFilter,
        filterSubtype: .contrast,
        filterName: "CIColorControls",
        displayName: String(localized: "Contrast"),
        filterIcon: UIImage(systemName: "circle.lefthalf.filled")!,
        filterKey: kCIInputContrastKey,
        filterDefaultValue: 1.0,
        minimumValue: 0.9,
        maximumValue: 1.1)

    lazy var saturationFilter = Filter(
        filterType: .editingFilter,
        filterSubtype: .saturation,
        filterName: "CIColorControls",
        displayName: String(localized: "Saturation"),
        filterIcon: UIImage(systemName: "drop")!,
        filterKey: kCIInputSaturationKey,
        filterDefaultValue: 1.00,
        minimumValue: 0.0,
        maximumValue: 2.0)

    lazy var warmthFilter = Filter(
        filterType: .editingFilter,
        filterSubtype: .warmth,
        filterName: "CITemperatureAndTint",
        displayName: String(localized: "Warmth"),
        filterIcon: UIImage(systemName: "thermometer.sun")!,
        filterKey: "inputTargetNeutral",
        filterDefaultValue: 0,
        minimumValue: -2000.0,
        maximumValue: 2000.0)

    lazy var tintFilter = Filter(
        filterType: .editingFilter,
        filterSubtype: .tint,
        filterName: "CITemperatureAndTint",
        displayName: String(localized: "Tint"),
        filterIcon: UIImage(systemName: "eyedropper.halffull")!,
        filterKey: "inputTargetNeutral",
        filterDefaultValue: 0.0,
        minimumValue: -100.0,
        maximumValue: 100.0)

    lazy var highlightsFilter = Filter(
        filterType: .editingFilter,
        filterSubtype: .highlihts,
        filterName: "CIHighlightShadowAdjust",
        displayName: String(localized: "Highlights"),
        filterIcon: UIImage(systemName: "circle.fill")!,
        filterKey: "inputHighlightAmount",
        filterDefaultValue: 1.0,
        minimumValue: 0.0,
        maximumValue: 2.0)

    lazy var shadowsFilter = Filter(
        filterType: .editingFilter,
        filterSubtype: .shadows,
        filterName: "CIHighlightShadowAdjust",
        displayName: String(localized: "Shadows"),
        filterIcon: UIImage(systemName: "circle.fill")!,
        filterKey: "inputShadowAmount",
        filterDefaultValue: 0.0,
        minimumValue: -0.8,
        maximumValue: 0.8)

    lazy var vignetteFilter = Filter(
        filterType: .editingFilter,
        filterSubtype: .vignette,
        filterName: "CIVignette",
        displayName: String(localized: "Vignette"),
        filterIcon: UIImage(systemName: "smallcircle.filled.circle")!,
        filterKey: "inputIntensity",
        filterDefaultValue: 0.0,
        minimumValue: 0.0,
        maximumValue: 4.0)
}
