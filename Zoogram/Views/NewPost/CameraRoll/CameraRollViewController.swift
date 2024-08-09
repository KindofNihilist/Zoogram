//
//  CameraRollViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 10.02.2023.
//
import Photos
import UIKit

class CameraRollViewController: UIViewController {

    weak var delegate: NewPostProtocol?

    private(set) var factory: CameraRollFactory!
    private var dataSource: CollectionViewDataSource!

    private var userPhotos = [PHAsset]() {
        didSet {
            self.selectPhotoAsPreview(at: 0)
        }
    }

    private var selectedPhoto: UIImage? {
        didSet {
            if let photo = selectedPhoto {
                factory.setPreviewPhoto(using: photo)
                self.focusOnPreview(animated: true)
            }
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    lazy var cameraRollCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionHeadersPinToVisibleBounds = true
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: PhotoCollectionViewCell.identifier)
        collectionView.backgroundColor = .black
        return collectionView
    }()

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupFactory()
        view.backgroundColor = .black
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.configureNavigationBarColor(with: .black)
        self.navigationController?.isNavigationBarHidden = true
        if isMovingToParent {
            fetchUserPhotos {
                self.factory.updateCameraRoll(with: self.userPhotos)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }

    // MARK: Setup methods
    private func setupViews() {
        view.addSubview(cameraRollCollectionView)
        NSLayoutConstraint.activate([
            cameraRollCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cameraRollCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraRollCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraRollCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

    }

    // MARK: Photos fetching
    private func fetchUserPhotos(completion: @escaping () -> Void = {}) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            switch status {
            case .authorized:
                let fetchOptions = PHFetchOptions()
                let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                self?.userPhotos = assets.objects(at: IndexSet(integersIn: Range(uncheckedBounds: (0, assets.count)))).reversed()
                DispatchQueue.main.async {
                    completion()
                }
            default:
                self?.showPhotoLibraryAuthorizationError()
            }
        }
    }

    private func selectPhotoAsPreview(at path: Int, completion: @escaping () -> Void = {}) {
        let asset = userPhotos[path]

        DispatchQueue.main.async {
            self.factory.showNavigationLoadingIndicator()
        }
        let previewOptions = PHImageRequestOptions()
        previewOptions.deliveryMode = .fastFormat
        previewOptions.version = .current
        PHCachingImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .default,
            options: previewOptions) { previewImage, _ in
                if let previewImage = previewImage {
                    self.selectedPhoto = previewImage
                }
            }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.version = .current
        PHCachingImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
            if let data = data {
                let image = UIImage(data: data)
                if let image = image {
                    self.selectedPhoto = image
                    self.factory.showNavigationNextButton()
                }
             }
        }
    }

    private func showPhotoLibraryAuthorizationError(description: String? = nil) {
        let title = String(localized: "Provide Photo Library access")
        let message = description ?? String(localized: "Access to photo library is needed to choose a photo to post")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: String(localized: "Settings"), style: .default) { _ in
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(settingsURL)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(action)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    // MARK: Factory Setup
    private func setupFactory() {
        self.factory = CameraRollFactory(for: cameraRollCollectionView, action: { [weak self] indexPath in
            self?.selectPhotoAsPreview(at: indexPath.row)
        })
        self.factory.headerDelegate = self
        self.setupDataSource()
        self.factory.setNavigationSectionLeftButtonAction { [weak self] in
            self?.dismiss(animated: true)
        }

        self.factory.setNavigationSectionRightButtonAction { [weak self] in
            self?.navigateToEdditor()
        }
    }

    private func setupDataSource() {
        factory.buildSections(photos: self.userPhotos)
        self.dataSource = DefaultCollectionViewDataSource(sections: factory.sections)
        self.cameraRollCollectionView.dataSource = self.dataSource
        self.cameraRollCollectionView.delegate = self.dataSource
        self.cameraRollCollectionView.reloadData()
    }

    private func focusOnPreview(animated: Bool) {
        guard let cameraRollHeaderAttributes = cameraRollCollectionView.layoutAttributesForSupplementaryElement(
                ofKind: UICollectionView.elementKindSectionHeader,
                at: IndexPath(item: 0, section: 0))
        else {
            return
        }

        var offsetY = cameraRollHeaderAttributes.frame.origin.y - cameraRollCollectionView.contentInset.top
        if #available(iOS 11.0, *) {
            offsetY -= cameraRollCollectionView.safeAreaInsets.top
        }
        cameraRollCollectionView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: animated)
    }

    private func navigateToEdditor() {
        self.factory.showNavigationLoadingIndicator()
        self.factory.getPreviewImage { photo in
            ImageCompressor.compress(image: photo) { compressedImage in
                DispatchQueue.main.async {
                    let editingVC = PhotoEditingViewController(photo: compressedImage)
                    editingVC.delegate = self.delegate
                    self.factory.showNavigationNextButton()
                    self.navigationController?.pushViewController(editingVC, animated: true)
                }
            }
        }
    }

    // MARK: Action methods

    @objc private func dismissSelf() {
        self.dismiss(animated: true)
    }
}

extension CameraRollViewController: CameraRollHeaderDelegate {
    func didTapCameraButton(_ header: CameraRollHeaderView) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = self
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        picker.dismiss(animated: true) {
            self.selectedPhoto = image
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
