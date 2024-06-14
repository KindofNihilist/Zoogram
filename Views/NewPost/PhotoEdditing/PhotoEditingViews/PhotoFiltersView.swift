//
//  PhotoFiltersView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 21.11.2023.
//

import UIKit

@MainActor protocol PhotoFiltersViewDelegate: AnyObject {
    func userHasSelected(button: EdditingFilterButton, with filter: PhotoFilter)
}

struct FilterButton {
    let effectName: String
    let effectIcon: UIImage
}

class PhotoFiltersView: UIView {

    weak var delegate: PhotoFiltersViewDelegate?

    var photoFilters = ImageFilters()

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
        stackview.spacing = 6
        stackview.alignment = .center
        stackview.distribution = .equalSpacing
        return stackview
    }()

    private lazy var withoutFilterButton: PhotoFilterButton = {
        let button = PhotoFilterButton()
        button.addTarget(self, action: #selector(didSelectWithoutFilter), for: .touchUpInside)
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var noirFilterButton: PhotoFilterButton = {
        let button = PhotoFilterButton()
        button.addTarget(self, action: #selector(didSelectNoirFilter), for: .touchUpInside)
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var vividFilterButton: PhotoFilterButton = {
        let button = PhotoFilterButton()
        button.addTarget(self, action: #selector(didSelectVividFilter), for: .touchUpInside)
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var honeyFilterButton: PhotoFilterButton = {
        let button = PhotoFilterButton()
        button.addTarget(self, action: #selector(didSelectHoneyFilter), for: .touchUpInside)
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var sillyFilterButton: PhotoFilterButton = {
        let button = PhotoFilterButton()
        button.addTarget(self, action: #selector(didSelectSillyFilter), for: .touchUpInside)
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var funkyFilterButton: PhotoFilterButton = {
        let button = PhotoFilterButton()
        button.addTarget(self, action: #selector(didSelectFunkyFilter), for: .touchUpInside)
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var pawsFilterButton: PhotoFilterButton = {
        let button = PhotoFilterButton()
        button.addTarget(self, action: #selector(didSelectPawsFilter), for: .touchUpInside)
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var coldMonkeyFilterButton: PhotoFilterButton = {
        let button = PhotoFilterButton()
        button.addTarget(self, action: #selector(didSelectColdMonkeyFilter), for: .touchUpInside)
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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupScrollViewButtons() {
        stackView.addArrangedSubviews(
            withoutFilterButton,
            vividFilterButton,
            honeyFilterButton,
            pawsFilterButton,
            sillyFilterButton,
            funkyFilterButton,
            coldMonkeyFilterButton,
            noirFilterButton)
    }

    func setupFilterPreviews(for image: CIImage) {
        guard let withoutFilterPreview = photoFilters.withoutFilter.getFilterPreview(for: image),
              let noirPreview = photoFilters.noirPhotoFilter.getFilterPreview(for: image),
              let vividPreview = photoFilters.vividPhotoFilter.getFilterPreview(for: image),
              let honeyPreview = photoFilters.honeyPhotoFilter.getFilterPreview(for: image),
              let sillyPreview = photoFilters.sillyPhotoFilter.getFilterPreview(for: image),
              let funkyPreview = photoFilters.funkyPhotoFilter.getFilterPreview(for: image),
              let pawsPreview = photoFilters.pawsPhotoFilter.getFilterPreview(for: image),
              let coldMonkeyPreview = photoFilters.coldMonkeyPhotoFilter.getFilterPreview(for: image)
        else {
            return
        }
        withoutFilterButton.configure(effectIcon: withoutFilterPreview, effectName: photoFilters.withoutFilter.displayName)
        noirFilterButton.configure(effectIcon: noirPreview, effectName: photoFilters.noirPhotoFilter.displayName)
        vividFilterButton.configure(effectIcon: vividPreview, effectName: photoFilters.vividPhotoFilter.displayName)
        honeyFilterButton.configure(effectIcon: honeyPreview, effectName: photoFilters.honeyPhotoFilter.displayName)
        sillyFilterButton.configure(effectIcon: sillyPreview, effectName: photoFilters.sillyPhotoFilter.displayName)
        funkyFilterButton.configure(effectIcon: funkyPreview, effectName: photoFilters.funkyPhotoFilter.displayName)
        pawsFilterButton.configure(effectIcon: pawsPreview, effectName: photoFilters.pawsPhotoFilter.displayName)
        coldMonkeyFilterButton.configure(effectIcon: coldMonkeyPreview, effectName: photoFilters.coldMonkeyPhotoFilter.displayName)
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

    @objc private func didSelectWithoutFilter(button: EdditingFilterButton) {
        self.delegate?.userHasSelected(button: button, with: photoFilters.withoutFilter)
    }

    @objc private func didSelectNoirFilter(button: EdditingFilterButton) {
        self.delegate?.userHasSelected(button: button, with: photoFilters.noirPhotoFilter)
    }

    @objc private func didSelectVividFilter(button: EdditingFilterButton) {
        self.delegate?.userHasSelected(button: button, with: photoFilters.vividPhotoFilter)
    }

    @objc private func didSelectHoneyFilter(button: EdditingFilterButton) {
        self.delegate?.userHasSelected(button: button, with: photoFilters.honeyPhotoFilter)
    }

    @objc private func didSelectSillyFilter(button: EdditingFilterButton) {
        self.delegate?.userHasSelected(button: button, with: photoFilters.sillyPhotoFilter)
    }

    @objc private func didSelectFunkyFilter(button: EdditingFilterButton) {
        self.delegate?.userHasSelected(button: button, with: photoFilters.funkyPhotoFilter)
    }

    @objc private func didSelectPawsFilter(button: EdditingFilterButton) {
        self.delegate?.userHasSelected(button: button, with: photoFilters.pawsPhotoFilter)
    }

    @objc private func didSelectColdMonkeyFilter(button: EdditingFilterButton) {
        self.delegate?.userHasSelected(button: button, with: photoFilters.coldMonkeyPhotoFilter)
    }
}
