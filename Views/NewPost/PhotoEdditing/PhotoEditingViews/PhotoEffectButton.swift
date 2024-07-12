//
//  PhotoEffectButton.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 14.02.2022.
//

import UIKit

class EdditingFilterButton: UIButton {

    var hasBeenAlreadySelected: Bool = false

    typealias HasApplieadRelatedEffect = Bool

    dynamic var onStatusChange: ((HasApplieadRelatedEffect) -> Void)?

    var hasAppliedRelatedEffect: Bool = false {
        didSet {
            if let closure = onStatusChange {
                closure(hasAppliedRelatedEffect)
            }
        }
    }

    func setSelected() {
        self.hasBeenAlreadySelected = true
        self.hasAppliedRelatedEffect = true
    }

    func setDeselected() {
        self.hasBeenAlreadySelected = false
        self.hasAppliedRelatedEffect = false
    }
}

class PhotoEffectButton: EdditingFilterButton {

    private lazy var roundBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.darkGray.cgColor
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var effectIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()

    private lazy var effectLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = CustomFonts.boldFont(ofSize: 13)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()

    lazy var isAppliedIndicator: UIView = {
        var indicator = UIView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.clipsToBounds = true
        indicator.isHidden = true
        indicator.backgroundColor = .white
        indicator.layer.cornerRadius = 5 / 2
        return indicator
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews(roundBackgroundView, effectLabel, isAppliedIndicator)
        roundBackgroundView.addSubview(effectIcon)
        setupConstraints()
        onStatusChange = { isRelatedEffectApplied in
            self.isAppliedIndicator.isHidden = !isRelatedEffectApplied
            print("Is Applied Indicator hidden: \(self.isAppliedIndicator.isHidden)")
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        roundBackgroundView.layer.cornerRadius = 85 / 2
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            effectLabel.topAnchor.constraint(equalTo: self.topAnchor),
            effectLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            effectLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),

            roundBackgroundView.topAnchor.constraint(equalTo: effectLabel.bottomAnchor, constant: 10),
            roundBackgroundView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            roundBackgroundView.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor),
            roundBackgroundView.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor),
            roundBackgroundView.widthAnchor.constraint(equalToConstant: 85),
            roundBackgroundView.heightAnchor.constraint(equalToConstant: 85),

            effectIcon.centerXAnchor.constraint(equalTo: roundBackgroundView.centerXAnchor),
            effectIcon.centerYAnchor.constraint(equalTo: roundBackgroundView.centerYAnchor),
            effectIcon.widthAnchor.constraint(equalToConstant: 45),
            effectIcon.heightAnchor.constraint(equalToConstant: 45),

            isAppliedIndicator.topAnchor.constraint(equalTo: roundBackgroundView.bottomAnchor, constant: 10),
            isAppliedIndicator.centerXAnchor.constraint(equalTo: roundBackgroundView.centerXAnchor),
            isAppliedIndicator.heightAnchor.constraint(equalToConstant: 5),
            isAppliedIndicator.widthAnchor.constraint(equalToConstant: 5),
            isAppliedIndicator.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor)
        ])
    }

    func configure(effectIcon: UIImage, effectName: String) {
        self.effectIcon.image = effectIcon
        self.effectLabel.text = effectName
    }
}
