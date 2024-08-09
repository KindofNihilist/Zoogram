//
//  CameraRollFactory.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 15.11.2023.
//

import Foundation
import Photos.PHFetchResult
import UIKit.UICollectionView

@MainActor class CameraRollFactory {

    private var collectionView: UICollectionView

    weak var headerDelegate: CameraRollHeaderDelegate?

    private var action: ((IndexPath) -> Void)

    var sections = [CollectionSectionController]()

    private var navigationSection: NavigationSection!

    private var previewSection: PreviewSection!

    private var cameraRollSection: CameraRollSection!

    init(for collectionView: UICollectionView, action: @escaping (IndexPath) -> Void) {
        self.collectionView = collectionView
        self.action = action
    }

    func buildSections(photos: [PHAsset]) {

        navigationSection = NavigationSection(sectionHolder: collectionView, cellControllers: [], sectionIndex: 0)

        sections.append(navigationSection)

        previewSection = PreviewSection(sectionHolder: collectionView, cellControllers: [], sectionIndex: 1)
        sections.append(previewSection)

        let cellControllers = photos.map { asset in
            return CameraRollCellController(photo: asset, action: action)
        }
        cameraRollSection = CameraRollSection(sectionHolder: collectionView, cellControllers: cellControllers, sectionIndex: 2)
        cameraRollSection.delegate = headerDelegate
        sections.append(cameraRollSection)
    }

    func updateCameraRoll(with assets: [PHAsset]?) {
        guard let unwrappedAssets = assets else { return }
        let cellControllers = unwrappedAssets.map { asset in
            return CameraRollCellController(photo: asset, action: action)
        }
        cameraRollSection.cellControllers.removeAll()
        cameraRollSection.cellControllers = cellControllers
        collectionView.reloadSections(IndexSet(integer: cameraRollSection.sectionIndex))
    }

    func setPreviewPhoto(using image: UIImage) {
        previewSection.previewImage = image
        if let previewHeader = previewSection.getHeader() as? PreviewHeaderView {
            previewHeader.updatePreview(with: image)
        }

    }

    func getPreviewImage(completion: (UIImage) -> Void) {
        guard let previewHeader = previewSection.getHeader() as? PreviewHeaderView else { return }
        completion(previewHeader.getPreviewImage())
    }

    func showNavigationLoadingIndicator() {
        if let navigationHeader = navigationSection.header {
            navigationHeader.showLoadingIndicator()
        }
    }

    func showNavigationNextButton() {
        navigationSection.header?.showNextButton()
    }

    func setNavigationSectionLeftButtonAction(_ action: @escaping () -> Void) {
        navigationSection.leftButtonAction = action
    }

    func setNavigationSectionRightButtonAction(_ action: @escaping () -> Void) {
        navigationSection.rightButtonAction = action
    }
}
