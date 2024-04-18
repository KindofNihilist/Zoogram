//
//  PhotoEffectSliderView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 15.02.2022.
//

import UIKit

protocol PhotoEffectSliderDelegate: AnyObject {
    func didChangeSliderValue(value: Float)
    func cancelFilterApplication()
    func saveFilterApplication()
}

class FilterValueSliderView: UIView {

    weak var delegate: PhotoEffectSliderDelegate?

    var hapticEngine = UIImpactFeedbackGenerator(style: .rigid)

    var isInverted: Bool = false {
        didSet {
            self.setInvertionState()
        }
    }

    private lazy var slider: CustomSlider = {
        let slider = CustomSlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.tintColor = .systemFill
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        slider.minimumTrackTintColor = .white
        slider.maximumTrackTintColor = .white
        return slider
    }()

    private lazy var sliderCenterIndicator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.isHidden = true
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = 3 / 2
        return view
    }()

    private let effectNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = CustomFonts.boldFont(ofSize: 17)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        let title = String(localized: "Cancel")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = CustomFonts.boldFont(ofSize: 15)
        button.titleLabel?.textColor = .white
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var doneButton: UIButton = {
        let button = UIButton()
        let title = String(localized: "Done")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = CustomFonts.boldFont(ofSize: 15)
        button.titleLabel?.textColor = .white
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews(sliderCenterIndicator, slider, effectNameLabel, cancelButton, doneButton)
        setupConstraints()
        hapticEngine.prepare()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([

            effectNameLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 40),
            effectNameLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            effectNameLabel.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -30),
            effectNameLabel.heightAnchor.constraint(equalToConstant: 30),

            slider.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            slider.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            slider.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -40),
            slider.heightAnchor.constraint(equalToConstant: slider.thumbDiameter),

            sliderCenterIndicator.centerXAnchor.constraint(equalTo: slider.centerXAnchor),
            sliderCenterIndicator.topAnchor.constraint(equalTo: slider.topAnchor),
            sliderCenterIndicator.widthAnchor.constraint(equalToConstant: 3),
            sliderCenterIndicator.heightAnchor.constraint(equalToConstant: 3),

            cancelButton.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: self.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),

            doneButton.leadingAnchor.constraint(equalTo: self.centerXAnchor),
            doneButton.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            doneButton.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor),
            doneButton.heightAnchor.constraint(equalTo: cancelButton.heightAnchor)
        ])
    }

    private func setInvertionState() {
        if self.isInverted {
            slider.transform = CGAffineTransform(scaleX: -1, y: 1)
        } else {
            slider.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }

    func configure(for filter: FilterDelegate) {
        let effectName = filter.displayName
        let sliderDefaultValue = filter.defaultValue
        let sliderMaximumValue = filter.maximumValue
        let sliderMinimumValue = filter.minimumValue
        let latestValue = filter.latestValue
        self.effectNameLabel.text = effectName
        self.slider.setValuesRange(minimumValue: sliderMinimumValue, maximumValue: sliderMaximumValue, defaultValue: sliderDefaultValue, latestValue: latestValue)
        if sliderDefaultValue > sliderMinimumValue && sliderDefaultValue < sliderMaximumValue {
            self.sliderCenterIndicator.isHidden = false
        } else {
            self.sliderCenterIndicator.isHidden = true
        }
    }

    func getSliderValue() -> Float {
        return slider.value
    }

    @objc private func sliderValueChanged() {
        let isInsideDeadzone = slider.checkIfInsideDeadzone()

        if isInsideDeadzone && slider.shouldTriggerHapticFeedback {
            hapticEngine.impactOccurred()
            slider.shouldTriggerHapticFeedback = false
        } else if !isInsideDeadzone {
            slider.shouldTriggerHapticFeedback = true
        }

        self.delegate?.didChangeSliderValue(value: slider.value)
    }

    @objc private func cancelButtonTapped() {
        self.delegate?.cancelFilterApplication()
    }

    @objc private func doneButtonTapped() {
        self.delegate?.saveFilterApplication()
    }
}
