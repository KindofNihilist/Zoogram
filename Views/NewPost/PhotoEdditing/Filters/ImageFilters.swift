//
//  ImageFilters.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 21.11.2023.
//

import UIKit

@MainActor
class ImageFilters {
    lazy var withoutFilter = WithoutFilter(displayName: String(localized: "Normal"), filterType: .normal)
    lazy var noirPhotoFilter = NoirPhotoFilter(displayName: "Noir", filterType: .noir)
    lazy var vividPhotoFilter = VividPhotoFilter(displayName: "Vivid", filterType: .vivid)
    lazy var honeyPhotoFilter = HoneyPhotoFilter(displayName: "Honey", filterType: .honey)
    lazy var sillyPhotoFilter = SillyPhotoFilter(displayName: "Silly", filterType: .silly)
    lazy var funkyPhotoFilter = FunkyPhotoFilter(displayName: "Funky", filterType: .funky)
    lazy var pawsPhotoFilter = PawsPhotoFilter(displayName: "Paws", filterType: .paws)
    lazy var coldMonkeyPhotoFilter = ColdMonkeyFilter(displayName: "Cold Monkey", filterType: .coldMonkey)
}

class WithoutFilter: PhotoFilter {

    override func applyFilter() {
        guard let inputImage = self.inputImage else {
            return
        }
        self.outputImage = inputImage
        self.filteredImage = inputImage
    }
}

class NoirPhotoFilter: PhotoFilter {
    private let saturation = effects.saturationFilter
    private let exposure = effects.exposureFilter
    private let shadows = effects.shadowsFilter
    private let contrast = effects.contrastFilter
    private let vignette = effects.vignetteFilter
    private let warmth = effects.warmthFilter

    override func applyFilter() {
        guard let inputImage = self.inputImage else {
            return
        }
        saturation.setInputImage(image: inputImage)
        saturation.applyFilter(sliderValue: 0.0)

        exposure.setInputImage(image: saturation.getOutput()!)
        exposure.applyFilter(sliderValue: -0.5)

        shadows.setInputImage(image: exposure.getOutput()!)
        shadows.applyFilter(sliderValue: -0.188)

        contrast.setInputImage(image: shadows.getOutput()!)
        contrast.applyFilter(sliderValue: 1.0114)

        vignette.setInputImage(image: contrast.getOutput()!)
        vignette.applyFilter(sliderValue: 1.714)

        warmth.setInputImage(image: vignette.getOutput()!)
        warmth.applyFilter(sliderValue: 1015)

        self.filteredImage = warmth.getOutput()
    }
}

class VividPhotoFilter: PhotoFilter {
    private let exposure = effects.exposureFilter
    private let contrast = effects.contrastFilter
    private let brightness = effects.brightnessFilter
    private let saturation = effects.saturationFilter
    private let shadows = effects.shadowsFilter

    override func applyFilter() {
        guard let inputImage = self.inputImage else {
            return
        }

        exposure.setInputImage(image: inputImage)
        exposure.applyFilter(sliderValue: 0.291)

        contrast.setInputImage(image: exposure.getOutput()!)
        contrast.applyFilter(sliderValue: 1.028)

        brightness.setInputImage(image: contrast.getOutput()!)
        brightness.applyFilter(sliderValue: -0.0029)

        saturation.setInputImage(image: brightness.getOutput()!)
        saturation.applyFilter(sliderValue: 1.103)

        shadows.setInputImage(image: saturation.getOutput()!)
        shadows.applyFilter(sliderValue: -0.105)

        self.filteredImage = shadows.getOutput()
    }
}

class HoneyPhotoFilter: PhotoFilter {
    private let exposure = effects.exposureFilter
    private let warmth = effects.warmthFilter
    private let brightness = effects.brightnessFilter
    private let shadows = effects.shadowsFilter
    private let contrast = effects.contrastFilter

    override func applyFilter() {
        guard let inputImage = self.inputImage else {
            return
        }
        warmth.setInputImage(image: inputImage)
        warmth.applyFilter(sliderValue: -1800)

        exposure.setInputImage(image: warmth.getOutput()!)
        exposure.applyFilter(sliderValue: 0.144)

        brightness.setInputImage(image: exposure.getOutput()!)
        brightness.applyFilter(sliderValue: 0.0094)

        shadows.setInputImage(image: brightness.getOutput()!)
        shadows.applyFilter(sliderValue: -0.079)

        contrast.setInputImage(image: shadows.getOutput()!)
        contrast.applyFilter(sliderValue: 1.0102)

        self.filteredImage = contrast.getOutput()
    }
}

class SillyPhotoFilter: PhotoFilter {
    private let saturation = effects.saturationFilter
    private let warmth = effects.warmthFilter
    private let tint = effects.tintFilter
    private let vignette = effects.vignetteFilter
    private let highLights = effects.highlightsFilter
    private let brightness = effects.brightnessFilter

    override func applyFilter() {
        guard let inputImage = self.inputImage else {
            return
        }

        saturation.setInputImage(image: inputImage)
        saturation.applyFilter(sliderValue: 1.46)

        warmth.setInputImage(image: saturation.getOutput()!)
        warmth.applyFilter(sliderValue: 189.62)

        tint.setInputImage(image: warmth.getOutput()!)
        tint.applyFilter(sliderValue: -49.40)

        vignette.setInputImage(image: tint.getOutput()!)
        vignette.applyFilter(sliderValue: 1.319)

        highLights.setInputImage(image: vignette.getOutput()!)
        highLights.applyFilter(sliderValue: 0.777)

        brightness.setInputImage(image: highLights.getOutput()!)
        brightness.applyFilter(sliderValue: 0.0084)

        self.filteredImage = brightness.getOutput()
    }
}

class FunkyPhotoFilter: PhotoFilter {
    private let exposure = effects.exposureFilter
    private let brightness = effects.brightnessFilter
    private let tint = effects.tintFilter
    private let vignette = effects.vignetteFilter
    private let shadows = effects.shadowsFilter
    private let highlights = effects.highlightsFilter
    private let contrast = effects.contrastFilter

    override func applyFilter() {
        guard let inputImage = self.inputImage else {
            return
        }

        exposure.setInputImage(image: inputImage)
        exposure.applyFilter(sliderValue: -0.248)

        brightness.setInputImage(image: exposure.getOutput()!)
        brightness.applyFilter(sliderValue: 0.026)

        tint.setInputImage(image: brightness.getOutput()!)
        tint.applyFilter(sliderValue: 47.604)

        vignette.setInputImage(image: tint.getOutput()!)
        vignette.applyFilter(sliderValue: 1.075)

        shadows.setInputImage(image: vignette.getOutput()!)
        shadows.applyFilter(sliderValue: -0.273)

        highlights.setInputImage(image: shadows.getOutput()!)
        highlights.applyFilter(sliderValue: 0.687)

        contrast.setInputImage(image: highlights.getOutput()!)
        contrast.applyFilter(sliderValue: 0.977)

        self.filteredImage = contrast.getOutput()
    }
}

class PawsPhotoFilter: PhotoFilter {
    private let contrast = effects.contrastFilter
    private let warmth = effects.warmthFilter
    private let shadows = effects.shadowsFilter
    private let vignette = effects.vignetteFilter
    private let brightness = effects.brightnessFilter

    override func applyFilter() {
        guard let inputImage = self.inputImage else {
            return
        }

        contrast.setInputImage(image: inputImage)
        contrast.applyFilter(sliderValue: 1.012)

        warmth.setInputImage(image: contrast.getOutput()!)
        warmth.applyFilter(sliderValue: -1031.936)

        shadows.setInputImage(image: warmth.getOutput()!)
        shadows.applyFilter(sliderValue: 0.243)

        vignette.setInputImage(image: shadows.getOutput()!)
        vignette.applyFilter(sliderValue: 0.884)

        brightness.setInputImage(image: vignette.getOutput()!)
        brightness.applyFilter(sliderValue: 0.021)

        self.filteredImage = vignette.getOutput()
    }
}

class ColdMonkeyFilter: PhotoFilter {
    private let warmth = effects.warmthFilter
    private let saturation = effects.saturationFilter
    private let brightness = effects.brightnessFilter
    private let contrast = effects.contrastFilter
    private let shadows = effects.shadowsFilter

    override func applyFilter() {
        guard let inputImage = self.inputImage else {
            return
        }

        saturation.setInputImage(image: inputImage)
        saturation.applyFilter(sliderValue: 1.094)

        brightness.setInputImage(image: saturation.getOutput()!)
        brightness.applyFilter(sliderValue: 0.010)

        contrast.setInputImage(image: brightness.getOutput()!)
        contrast.applyFilter(sliderValue: 0.9809)

        shadows.setInputImage(image: contrast.getOutput()!)
        shadows.applyFilter(sliderValue: -0.291)

        warmth.setInputImage(image: shadows.getOutput()!)
        warmth.applyFilter(sliderValue: 2000)

        self.filteredImage = warmth.getOutput()
    }
}
