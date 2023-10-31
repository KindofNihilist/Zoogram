//
//  PhotoEffectSliderView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 15.02.2022.
//

import UIKit

protocol PhotoEffectSliderDelegate: AnyObject {
    func didChangeSliderValue(value: Float)
    func cancelFilterApplication(view: UIView)
    func saveFilterApplication(view: UIView)
}

class PhotoEffectSliderView: UIView {

    weak var delegate: PhotoEffectSliderDelegate?

    private lazy var slider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.tintColor = .white
        slider.thumbTintColor = .systemMint
        slider.minimumValue = -1
        slider.maximumValue = 1.0
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        slider.minimumTrackTintColor = .white
        slider.maximumTrackTintColor = .white
        return slider
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
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = CustomFonts.boldFont(ofSize: 15)
        button.titleLabel?.textColor = .white
        button.setTitle("Cancel", for: .normal)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var doneButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = CustomFonts.boldFont(ofSize: 15)
        button.titleLabel?.textColor = .white
        button.setTitle("Done", for: .normal)
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        return button
    }()



    init(sliderDefaultValue: Float, sliderMaximumValue: Float, sliderMinimumValue: Float, effectName: String, key: String, isInverted: Bool) {
        super.init(frame: CGRect())
        self.effectNameLabel.text = effectName
        self.slider.value = sliderDefaultValue
        self.slider.minimumValue = sliderMinimumValue
        self.slider.maximumValue = sliderMaximumValue
        if isInverted {
            slider.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
        addSubviews(slider, effectNameLabel, cancelButton, doneButton)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([

            effectNameLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
            effectNameLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            effectNameLabel.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -30),
            effectNameLabel.heightAnchor.constraint(equalToConstant: 30),

            slider.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            slider.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            slider.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -40),
            slider.heightAnchor.constraint(equalToConstant: 40),

            cancelButton.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: self.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),

            doneButton.leadingAnchor.constraint(equalTo: self.centerXAnchor),
            doneButton.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            doneButton.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor),
            doneButton.heightAnchor.constraint(equalTo: cancelButton.heightAnchor),
        ])
    }

    @objc private func sliderValueChanged() {
        self.delegate?.didChangeSliderValue(value: slider.value)
    }

    @objc private func cancelButtonTapped() {
        self.delegate?.cancelFilterApplication(view: self)
    }

    @objc private func doneButtonTapped() {
        self.delegate?.saveFilterApplication(view: self)
    }

}
