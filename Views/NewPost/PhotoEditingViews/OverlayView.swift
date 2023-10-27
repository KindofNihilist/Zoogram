//
//  OverlayView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 05.05.2023.
//

import UIKit

final class OverlayView: UIView {
    let cropView = UIView()

    private let fadeView = UIView()

    private var overlayViewWidthConstraint: NSLayoutConstraint?
    private var overlayViewHeightConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle
    init(cropRatio: CGFloat) {
        super.init(frame: .zero)

        fadeView.translatesAutoresizingMaskIntoConstraints = false
        fadeView.isUserInteractionEnabled = false
        addSubview(fadeView)

        cropView.backgroundColor = UIColor.clear
        cropView.isUserInteractionEnabled = false
        cropView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cropView)

        NSLayoutConstraint.activate([
            fadeView.leadingAnchor.constraint(equalTo: leadingAnchor),
            fadeView.centerXAnchor.constraint(equalTo: centerXAnchor),
            fadeView.centerYAnchor.constraint(equalTo: centerYAnchor),
            fadeView.topAnchor.constraint(equalTo: topAnchor),

            cropView.topAnchor.constraint(equalTo: self.topAnchor),
            cropView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            cropView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            cropView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard overlayViewWidthConstraint == nil,
              overlayViewHeightConstraint == nil else {
            return
        }

        overlayViewWidthConstraint = widthAnchor.constraint(equalToConstant: frame.width)
        overlayViewWidthConstraint?.priority = .defaultHigh
        overlayViewWidthConstraint?.isActive = true

        overlayViewHeightConstraint = heightAnchor.constraint(equalToConstant: frame.height)
        overlayViewHeightConstraint?.priority = .defaultHigh
        overlayViewHeightConstraint?.isActive = true
    }
}
