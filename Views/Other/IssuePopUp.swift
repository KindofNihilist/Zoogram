//
//  IssuePopUp.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 19.03.2024.
//

import UIKit

class IssuePopUp: UIView {

    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "exclamationmark.circle")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private var issueDescriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = CustomFonts.regularFont(ofSize: 15)
        label.textColor = UIColor.white
        label.numberOfLines = 0
        label.sizeToFit()
        return label
    }()

    init(issueText: String) {
        super.init(frame: CGRect.zero)
        issueDescriptionLabel.text = issueText
        self.backgroundColor = Colors.popupBackground
        self.addSubviews(imageView, issueDescriptionLabel)
        self.setupConstraints()
        self.clipsToBounds = true
        self.layer.cornerRadius = 13
        self.layer.cornerCurve = .continuous
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 35),
            imageView.widthAnchor.constraint(equalToConstant: 35),

            issueDescriptionLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10),
            issueDescriptionLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            issueDescriptionLabel.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -25),
            issueDescriptionLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
}

extension UIViewController {

    @MainActor
    func showPopUp(issueText: String, completion: @escaping (() -> Void) = {}) {
        var isPopAlreadyDisplayed: Bool = false

        _ = self.view.subviews.map { view in
            isPopAlreadyDisplayed = view.isKind(of: IssuePopUp.self)
        }
        guard isPopAlreadyDisplayed == false else { return }

        let popupView = IssuePopUp(issueText: issueText)
        popupView.translatesAutoresizingMaskIntoConstraints = false
        popupView.alpha = 0
        view.addSubview(popupView)

        NSLayoutConstraint.activate([
            popupView.widthAnchor.constraint(equalTo: self.view.widthAnchor, constant: -20),
            popupView.heightAnchor.constraint(greaterThanOrEqualToConstant: 45),
            popupView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            popupView.bottomAnchor.constraint(equalTo: self.view.keyboardLayoutGuide.topAnchor, constant: -20)
        ])

        popupView.transform = CGAffineTransform(translationX: 0, y: 300)

        UIView.animate(withDuration: 0.4) {
            popupView.alpha = 1
            popupView.transform = .identity
        } completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                UIView.animate(withDuration: 0.6) {
                    popupView.alpha = 0
                } completion: { _ in
                    popupView.removeFromSuperview()
                    completion()
                }
            }
        }
    }
}
