//
//  File.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 27.11.2023.
//

import UIKit.UISlider

class CustomSlider: UISlider {

    var  trackHeight: CGFloat = 2

    var hapticTriggeringRange: ClosedRange<Float> = 0...1
    var hapticDeadzonePercent: Float = 4
    var shouldSnapToCenter: Bool = false
    var thumbDiameter: CGFloat = 23
    var defaultValue: Float = 0
    var shouldTriggerHapticFeedback: Bool = false

    private lazy var thumbImageView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemMint
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let thumbImage = createThumbImage(with: thumbDiameter)
        setThumbImage(thumbImage, for: .normal)
        setThumbImage(thumbImage, for: .highlighted)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var rectWithTrackHeight = super.trackRect(forBounds: bounds)
        rectWithTrackHeight.size.height = self.trackHeight
        return rectWithTrackHeight
    }

    private func createThumbImage(with diameter: CGFloat) -> UIImage {
        thumbImageView.frame = CGRect(x: 0, y: diameter / 2, width: diameter, height: diameter)
        thumbImageView.layer.cornerRadius = diameter / 2

        let renderer = UIGraphicsImageRenderer(bounds: thumbImageView.bounds)
        return renderer.image { context in
            thumbImageView.layer.render(in: context.cgContext)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // if default value is not in the center, no centering should be done

        guard shouldSnapToCenter else {
            return
        }
        if changesAreInsignificant() {
            snapThumbToCenter()
        }
    }

    private func changesAreInsignificant() -> Bool {
        let totalValue = abs(self.maximumValue - self.minimumValue)
        let changeDifference = totalValue - abs(self.value - defaultValue)
        let changePercent = abs(((totalValue - changeDifference) / totalValue) * 100)
        return changePercent < self.hapticDeadzonePercent
    }

    private func snapThumbToCenter() {
        self.setValue(defaultValue, animated: true)
        self.sendActions(for: .valueChanged)
    }

    func checkIfInsideDeadzone() -> Bool {
        return value > hapticTriggeringRange.lowerBound && value < hapticTriggeringRange.upperBound
    }

    func setValuesRange(minimumValue: Float, maximumValue: Float, defaultValue: Float, latestValue: Float) {
        self.minimumValue = minimumValue
        self.maximumValue = maximumValue
        self.value = latestValue
        self.defaultValue = defaultValue

        if defaultValue != maximumValue && defaultValue != minimumValue {
            shouldSnapToCenter = true
            setHapticTriggeringRangeFor(minimumValue: minimumValue, maximumValue: maximumValue)
        }
    }

    private func setHapticTriggeringRangeFor(minimumValue: Float, maximumValue: Float) {
        let totalValue = abs(maximumValue - minimumValue)
        let hapticDeadzonePercentValue = (totalValue / 100) * self.hapticDeadzonePercent
        let leftDeadzoneBound = defaultValue - hapticDeadzonePercentValue
        let rightDeadzoneBound = defaultValue + hapticDeadzonePercentValue
        self.hapticTriggeringRange = leftDeadzoneBound...rightDeadzoneBound
    }
}
