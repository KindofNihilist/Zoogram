//
//  MakePostViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 17.01.2022.
//

import UIKit
import Photos

class NewPostViewController: UIViewController {

    let inset: CGFloat = 0
    let minimumLineSpacing: CGFloat = 1
    let minimumInterItemSpacing: CGFloat = 1
    let cellsPerRow = 4
    var isAspectFit = false
    private var selectedPhoto: UIImage?

    var photoPreviewView: CameraRollPreviewHeader?

    var userPhotos: PHFetchResult<PHAsset>?

    private var userPhotoLibraryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.backgroundColor = .black
        return collectionView
    }()

    override init(nibName: String?, bundle: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        title = "New Post"
        view.backgroundColor = .black
        userPhotoLibraryCollectionView.delegate = self
        userPhotoLibraryCollectionView.dataSource = self
        setupConstraints()
        setupNavBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        fetchUserPhotos {
            self.selectPhotoAsPreview(at: 0)
        }

        //        if let layout = self.userPhotoLibraryCollectionView.collectionViewLayout as? UICollectionViewFlowLayout{
        //            self.assetThumbnailSize = layout.itemSize
        //            }
        //        self.photosAsset = (PHAsset.fetchAssets(in: self.assetCollection, options: nil) as AnyObject?) as! PHFetchResult<AnyObject>?
        //        self.userPhotoLibraryCollectionView.reloadData()
    }

    private func setupNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"),
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(dismissSelf))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapNext))
        navigationItem.leftBarButtonItem?.tintColor = .white
    }

    func selectPhotoAsPreview(at path: Int, completion: @escaping () -> Void = {}) {
        let asset = userPhotos?.object(at: path)
        let photoSize = CGSize(width: view.frame.width, height: view.frame.width)
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat

        PHCachingImageManager.default().requestImage(for: asset!,
                                                     targetSize: photoSize,
                                                     contentMode: .aspectFill,
                                                     options: options) { image, _ in
            guard let image = image else {
                return
            }
            self.selectedPhoto = image
            self.photoPreviewView?.update(with: image)
            completion()
        }
    }

    private func fetchUserPhotos(completion: @escaping () -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            switch status {
            case .authorized:
                print("Authorized")
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                self?.userPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                print("Photos in library", self?.userPhotos?.count)
                DispatchQueue.main.async {
                    self?.userPhotoLibraryCollectionView.reloadData()
                    self?.userPhotoLibraryCollectionView.scrollToItem(at: IndexPath(item: 0, section: 1),
                                                                      at: .top,
                                                                      animated: false)
                    completion()
                }

            case .denied:
                print("Access denied")
            case .notDetermined:
                print("Not determined")
            case .restricted:
                print("Restricted")
            case .limited:
                print("Limited")
            }
        }
    }

    private func setupConstraints() {
        view.addSubviews(userPhotoLibraryCollectionView)
        NSLayoutConstraint.activate([
            userPhotoLibraryCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            userPhotoLibraryCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            userPhotoLibraryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            userPhotoLibraryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

    }

    @objc private func didTapNext() {
        guard let photo = selectedPhoto, selectedPhoto != nil else {
            return
        }
        //        let editingVC = PhotoEditingViewController(photo: photo, isAspectFit: isAspectFit)
        let editingVC = PhotoEditingViewController(photo: photo)
        navigationController?.pushViewController(editingVC, animated: true)
    }

    @objc private func dismissSelf() {
        self.dismiss(animated: true)
    }

    //    @objc private func didTapAspectButton() {
    //        imagePreview.contentMode = .scaleAspectFill
    //    }
}

extension NewPostViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        }
        guard let photos = userPhotos, userPhotos != nil else {
            return 0
        }
        print("Photos count: \(photos.count)")
        return photos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let asset = userPhotos.object(at: indexPath.row) else {
            return UICollectionViewCell()
        }
        let cell: PhotoCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath)
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isSynchronous = true
        let cacheImageManager = PHCachingImageManager.default()
        cacheImageManager.requestImage(for: asset,
                                       targetSize: cell.frame.size,
                                       contentMode: .aspectFill,
                                       options: options) { image, _ in
            guard let image = image else {
                return
            }
            cell.configure(with: image)
        }

        return cell
    }

    //    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    //        guard kind == UICollectionView.elementKindSectionHeader else {
    //            return UICollectionReusableView()
    //        }
    //        if indexPath.section == 0 {
    //            let cameraRollPreview = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CameraRollPreviewHeader.identifier, for: indexPath) as! CameraRollPreviewHeader
    //            cameraRollPreview.update(with: selectedPhoto ?? UIImage())
    //            cameraRollPreview.delegate = self
    //            self.photoPreviewView = cameraRollPreview
    //            return cameraRollPreview
    //        } else {
    //            return UICollect
    //        }
    //    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectPhotoAsPreview(at: indexPath.row) {
            let indexPath = IndexPath(item: 0, section: 0)
            let header = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader,
                                                          at: indexPath) as? CameraRollPreviewHeader
            header?.update(with: self.selectedPhoto!)
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 1), at: .bottom, animated: true)
        }
    }

    // MARK: Collection View Layout Setup

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return CGSize(width: collectionView.frame.width, height: collectionView.frame.width)
        } else {

        }
        return CGSize(width: collectionView.frame.width, height: 50)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let safeAreaInsets = collectionView.safeAreaInsets.left + collectionView.safeAreaInsets.right
        let marginsAndInsets = inset * 2 + safeAreaInsets + minimumInterItemSpacing * CGFloat(cellsPerRow - 1)
        let itemWidth = ((collectionView.bounds.size.width - marginsAndInsets) / CGFloat(cellsPerRow)).rounded(.down)
        return CGSize(width: itemWidth, height: itemWidth)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return minimumLineSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return minimumInterItemSpacing
    }
}

extension NewPostViewController: CameraRollPreviewHeaderDelegate, CameraRollHeaderDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func didTapCameraButton(_ header: CameraRollHeaderView) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true) {
            self.selectedPhoto = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func updateImagePreview(with image: UIImage) {
    }

    func didChangeContentMode(isAspectFit: Bool) {
        self.isAspectFit = isAspectFit
        print("Changed aspect state: \(isAspectFit)")
    }
}
