//
//  PhotoEditingHorizontalStackView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 14.02.2022.
//

import UIKit

struct EditingButton {
    let effectName: String
    let effectIcon: UIImage
}

@MainActor protocol PhotoEffectsViewDelegate: AnyObject {
    func userHasSelected(button: EdditingFilterButton, with filter: ImageFilter)
}

class PhotoEffectsView: UIView {

    weak var delegate: PhotoEffectsViewDelegate?

    var edditingFilters = EditingFilters()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = false
        return scrollView
    }()

    private let stackView: UIStackView = {
        let stackview = UIStackView()
        stackview.translatesAutoresizingMaskIntoConstraints = false
        stackview.axis = .horizontal
        stackview.spacing = 10
        stackview.alignment = .center
        stackview.distribution = .equalSpacing
        return stackview
    }()

    private lazy var exposureButton: PhotoEffectButton = {
        let button = PhotoEffectButton()
        button.addTarget(self, action: #selector(didSelectExposureSetting), for: .touchUpInside)
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var brightnessButton: PhotoEffectButton = {
        let button = PhotoEffectButton()
        button.addTarget(self, action: #selector(didSelectBrightnessSetting), for: .touchUpInside)
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var contrastButton: PhotoEffectButton = {
        let button = PhotoEffectButton()
        button.addTarget(self, action: #selector(didSelectContrastSetting), for: .touchUpInside)
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var saturationButton: PhotoEffectButton = {
        let button = PhotoEffectButton()
        button.addTarget(self, action: #selector(didSelectSaturationSetting), for: .touchUpInside)
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var warmthButton: PhotoEffectButton = {
        let button = PhotoEffectButton()
        button.addTarget(self, action: #selector(didSelectWarmthSetting), for: .touchUpInside)
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var tintButton: PhotoEffectButton = {
        let button = PhotoEffectButton()
        button.addTarget(self, action: #selector(didSelectTintSetting), for: .touchUpInside)
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var highLightsButton: PhotoEffectButton = {
        let button = PhotoEffectButton()
        button.addTarget(self, action: #selector(didSelectHighlightsSetting), for: .touchUpInside)
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var shadowsButton: PhotoEffectButton = {
        let button = PhotoEffectButton()
        button.addTarget(self, action: #selector(didSelectShadowsSetting), for: .touchUpInside)
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var vignetteButton: PhotoEffectButton = {
        let button = PhotoEffectButton()
        button.addTarget(self, action: #selector(didSelectVignetteSetting), for: .touchUpInside)
        button.layer.masksToBounds = true
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        addSubviews(scrollView)
        scrollView.addSubview(stackView)
        setupConstraints()
        setupScrollViewButtons()
        configureButtons()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setupScrollViewButtons() {
        stackView.addArrangedSubviews(
            exposureButton,
            brightnessButton,
            contrastButton,
            saturationButton,
            warmthButton,
            tintButton,
            highLightsButton,
            shadowsButton,
            vignetteButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: self.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            stackView.topAnchor.constraint(greaterThanOrEqualTo: scrollView.topAnchor),
            stackView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.bottomAnchor)
        ])
    }

    private func configureButtons() {
        let buttons = [exposureButton, brightnessButton, contrastButton, saturationButton, warmthButton, tintButton, highLightsButton, shadowsButton, vignetteButton]
        for (index, filter) in edditingFilters.allFilters.enumerated() {
            buttons[index].configure(effectIcon: filter.filterIcon, effectName: filter.displayName)
        }
    }

    @objc private func didSelectExposureSetting(_ button: EdditingFilterButton) {
        self.delegate?.userHasSelected(button: button, with: edditingFilters.exposureFilter)
    }

    @objc private func didSelectBrightnessSetting(_ button: EdditingFilterButton) {
        self.delegate?.userHasSelected(button: button, with: edditingFilters.brightnessFilter)
    }

    @objc private func didSelectContrastSetting(_ button: EdditingFilterButton) {
        self.delegate?.userHasSelected(button: button, with: edditingFilters.contrastFilter)
    }

    @objc private func didSelectSaturationSetting(_ button: EdditingFilterButton) {
        self.delegate?.userHasSelected(button: button, with: edditingFilters.saturationFilter)
    }

    @objc private func didSelectWarmthSetting(_ button: EdditingFilterButton) {
        self.delegate?.userHasSelected(button: button, with: edditingFilters.warmthFilter)
    }

    @objc private func didSelectTintSetting(_ button: EdditingFilterButton) {
        self.delegate?.userHasSelected(button: button, with: edditingFilters.tintFilter)
    }

    @objc private func didSelectHighlightsSetting(_ button: EdditingFilterButton) {
        self.delegate?.userHasSelected(button: button, with: edditingFilters.highlightsFilter)
    }

    @objc private func didSelectShadowsSetting(_ button: EdditingFilterButton) {
        self.delegate?.userHasSelected(button: button, with: edditingFilters.shadowsFilter)
    }

    @objc private func didSelectVignetteSetting(_ button: EdditingFilterButton) {
        self.delegate?.userHasSelected(button: button, with: edditingFilters.vignetteFilter)
    }
}
