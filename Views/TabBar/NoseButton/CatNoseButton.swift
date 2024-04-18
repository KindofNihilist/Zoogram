//
//  CatNoseView.swift
//  CatNoseCALayer
//
//  Created by Artem Dolbiiev on 02.02.2024.
//

import UIKit
import CoreHaptics
import AVFoundation

protocol CatNoseDelegate: AnyObject {
    func didTapNose()
}

class CatNoseButton: UIButton {

    var currentNoseShape: CAShapeLayer!
    var catNose: CatNoseShape!
    var catSniffingNose: CatSniffingNose!
    var middleFold: CAGradientLayer!
    var leftNoseCanal: CAGradientLayer!
    var rightNoseCanal: CAGradientLayer!

    var engine: CHHapticEngine?
    var generator = UIImpactFeedbackGenerator(style: .light)

    lazy var supportsHaptics: Bool = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.supportsHaptics
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupNose()
        setupLayers()
        createHapticEngine()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        self.catNose.updateFrame(rect)
        self.catSniffingNose.updateFrame(rect)

        if let catNosePathBounds = catNose.path?.boundingBoxOfPath {
            self.middleFold.frame = catNosePathBounds
            self.middleFold.mask = NoseMiddleFoldShape(in: catNosePathBounds)
        }

        if let sniffingNosePathBounds = catSniffingNose.path?.boundingBoxOfPath {
            let adjustedScale = catSniffingNose.scaleFactor * 0.93
            self.leftNoseCanal.frame = sniffingNosePathBounds
            self.leftNoseCanal.mask = LeftNoseCanal(in: sniffingNosePathBounds, scaleFactor: adjustedScale)
            self.rightNoseCanal.frame = sniffingNosePathBounds
            self.rightNoseCanal.mask = RightNoseCanal(in: sniffingNosePathBounds, scaleFactor: adjustedScale)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        playHapticsFile(named: "CatPurr")
        animateNoseShapeChange(with: catSniffingNose)
        show(gradient: leftNoseCanal)
        show(gradient: rightNoseCanal)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        generator.prepare()
        generator.impactOccurred()
        animateNoseShapeChange(with: catNose)
        hide(gradient: leftNoseCanal)
        hide(gradient: rightNoseCanal)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        leftNoseCanal.removeFromSuperlayer()
        rightNoseCanal.removeFromSuperlayer()
        currentNoseShape.removeFromSuperlayer()
        middleFold.removeFromSuperlayer()
        setupNose()
        setupLayers()
    }

    private func setupNose() {
        self.catNose = CatNoseShape(in: frame)
        self.currentNoseShape = catNose
        self.catSniffingNose = CatSniffingNose(in: frame)
        self.middleFold = CatNoseButton.createMiddleFoldGradient(for: frame)
        self.leftNoseCanal = CatNoseButton.createNoseLeftCanalGradient(for: frame)
        self.rightNoseCanal = CatNoseButton.createNoseRightCanalGradient(for: frame)
    }

    private func setupLayers() {
        self.leftNoseCanal.isHidden = true
        self.rightNoseCanal.isHidden = true
        self.layer.addSublayer(leftNoseCanal)
        self.layer.addSublayer(rightNoseCanal)
        self.layer.addSublayer(currentNoseShape)
        self.layer.addSublayer(middleFold)
    }

    private func createHapticEngine() {
        do {

            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.ambient, mode: .default)
            engine = try CHHapticEngine(audioSession: audioSession)

        } catch let error {
            print("Engine Creation Error: \(error)")
        }

        guard let engine = engine else {
            print("Failed to create engine!")
            return
        }

        engine.resetHandler = {
            do {

                try self.engine?.start()

            } catch {
                print("Failed to restart the engine: \(error)")
            }
        }
    }

    private func playHapticsFile(named filename: String) {
        if !supportsHaptics {
            return
        }

        guard let path = Bundle.main.path(forResource: filename, ofType: "ahap") else {
            return
        }

        do {
            try engine?.start()
            try engine?.playPattern(from: URL(fileURLWithPath: path))
        } catch {
            print("An error occured playing \(filename): \(error).")
        }
    }

    private func animateNoseShapeChange(with shape: CAShapeLayer) {
        guard let unwrappedPath = shape.path else {
            return
        }
        self.currentNoseShape = shape
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = 0.1
        animation.toValue = unwrappedPath
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        catNose.add(animation, forKey: nil)
    }

    private func show(gradient: CAGradientLayer) {
        gradient.opacity = 1
        gradient.isHidden = false
        let animationGroup = CAAnimationGroup()
        var animation = CABasicAnimation(keyPath: "endPoint")
        animation.fromValue = leftNoseCanal.endPoint
        animation.toValue = leftNoseCanal.startPoint
        animation.duration = 0.1
        animation.isRemovedOnCompletion = true
        animationGroup.animations?.append(animation)

        var opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0
        opacityAnimation.toValue = 1
        opacityAnimation.duration = 0.1
        opacityAnimation.isRemovedOnCompletion = true
        animationGroup.animations?.append(opacityAnimation)
        gradient.add(animationGroup, forKey: nil)
    }

    private func hide(gradient: CAGradientLayer) {
        gradient.opacity = 0
        CATransaction.begin()
        var animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0
        animation.duration = 0.1
        animation.isRemovedOnCompletion = true
        CATransaction.setCompletionBlock {
            gradient.isHidden = true
        }
        gradient.add(animation, forKey: nil)
        CATransaction.commit()
    }


    static private func createMiddleFoldGradient(for frame: CGRect) -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.frame = frame
        let gradientStartColor = Colors.activeCatNoseColorScheme.bridgeGradient.firstColor.cgColor
        let gradientEndColor = Colors.activeCatNoseColorScheme.bridgeGradient.secondColor.cgColor
        gradient.colors = [gradientStartColor, gradientEndColor]
        gradient.startPoint = CGPoint(x: 0, y: 0.9)
        gradient.endPoint = CGPoint(x: 0, y: 0)
        gradient.mask = NoseMiddleFoldShape(in: frame)
        return gradient
    }

    static private func createNoseLeftCanalGradient(for frame: CGRect) -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.frame = frame
        let gradientStartColor = Colors.activeCatNoseColorScheme.nostrilGradient.firstColor.cgColor
        let gradientEndColor = Colors.activeCatNoseColorScheme.nostrilGradient.secondColor.cgColor
        gradient.colors = [gradientStartColor, gradientEndColor]
        let mask = LeftNoseCanal(in: frame)
        gradient.mask = mask
        gradient.startPoint = CGPoint(x: 0.4, y: 0.60)
        gradient.endPoint = CGPoint(x: 0.25, y: 0.80)
        return gradient
    }

    static private func createNoseRightCanalGradient(for frame: CGRect) -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.frame = frame
        let gradientStartColor = Colors.activeCatNoseColorScheme.nostrilGradient.firstColor.cgColor
        let gradientEndColor = Colors.activeCatNoseColorScheme.nostrilGradient.secondColor.cgColor
        gradient.colors = [gradientStartColor, gradientEndColor]
        let mask = RightNoseCanal(in: frame)
        gradient.mask = mask
        gradient.startPoint = CGPoint(x: 0.6, y: 0.60)
        gradient.endPoint = CGPoint(x: 0.75, y: 0.80)
        return gradient
    }
}
