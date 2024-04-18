//
//  GeneralProfileInfoCard.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 22.12.2023.
//

import UIKit

class GeneralProfileInfoCard: UIView {

    var delegate: ProfilePictureViewDelegate

    weak var textFieldDelegate: UITextFieldDelegate? {
        didSet {
            generalProfileInfoCardView.delegate = self.textFieldDelegate
        }
    }

    private lazy var generalProfileInfoCardView: ProfilePictureNameBioView = {
        let view = ProfilePictureNameBioView(profilePictureHeaderDelegate: delegate)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Colors.naturalBackground
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 20
        return view
    }()

    private lazy var ageAndGenderView: AgeGenderCardView = {
        let view = AgeGenderCardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Colors.naturalBackground
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 20
        view.isHidden = true
        return view
    }()

    init(profilePictureHeaderDelegate: ProfilePictureViewDelegate) {
        self.delegate = profilePictureHeaderDelegate
        super.init(frame: .zero)
        self.addSubviews(generalProfileInfoCardView, ageAndGenderView)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            generalProfileInfoCardView.topAnchor.constraint(equalTo: self.topAnchor),
            generalProfileInfoCardView.widthAnchor.constraint(equalTo: self.widthAnchor),
            generalProfileInfoCardView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            ageAndGenderView.topAnchor.constraint(equalTo: self.topAnchor),
            ageAndGenderView.widthAnchor.constraint(equalTo: self.widthAnchor),
            ageAndGenderView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    func flipToAgeAndGenderView() {
        let transitionOptions: UIView.AnimationOptions = [.transitionFlipFromRight, .showHideTransitionViews]
        UIView.transition(from: generalProfileInfoCardView,
                          to: ageAndGenderView,
                          duration: 1.0,
                          options: transitionOptions)
    }

    func flipToGeneralProfileInfoView() {
        let transitionOptions: UIView.AnimationOptions = [.transitionFlipFromLeft, .showHideTransitionViews]
        UIView.transition(from: ageAndGenderView,
                          to: generalProfileInfoCardView,
                          duration: 1.0,
                          options: transitionOptions)
    }

    func updateProfileHeaderPicture(with image: UIImage) {
        self.generalProfileInfoCardView.updateProfileHeaderPicture(with: image)
    }

    func getGender() -> String? {
        return ageAndGenderView.getGender()
    }

    func getDateOfBirth() -> String? {
        return ageAndGenderView.getDateOfBirth()
    }

    func getName() -> String? {
        return generalProfileInfoCardView.getName()
    }

    func getBio() -> String? {
        return generalProfileInfoCardView.getBio()
    }

    func showNameFieldIsEmptyError() {
        generalProfileInfoCardView.showNameFieldIsEmptyError()
    }

    func showGenderNotSelectedError() {
        ageAndGenderView.showGenderNotSelectedError()
    }

    func showDateOfBirthNotSelectedError() {
        ageAndGenderView.showDateOfBirthNotSelectedError()
    }

    func removeErrorStateForAgeAndGender() {
        ageAndGenderView.removeErrorState()
    }

    func removeEmptyErrorForName() {
        generalProfileInfoCardView.removeEmptyError()
    }
}

extension GeneralProfileInfoCard: TextFieldResponder {
    func becomeResponder() {
//        generalProfileInfoCardView.becomeResponder()
    }
    
    func resignResponder() {
        generalProfileInfoCardView.resignResponder()
    }
}
