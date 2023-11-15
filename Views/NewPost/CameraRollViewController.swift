//
//  CameraRollViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 10.02.2023.
//
import Photos
import UIKit

class CameraRollViewController: UIViewController {

    private var selectedPhoto: UIImage? {
        didSet {
            if let photo = selectedPhoto {
                previewCropView.changeImage(image: photo)
//                self.focusOnPreview(withDuration: 0.1)
            }
        }
    }

    weak var delegate: NewPostProtocol?

    var userPhotos: PHFetchResult<PHAsset>?
    
    var panStartingPoint: CGPoint?
    var panEndPoint: CGPoint?
    var distanceDifference: CGFloat?
    
    let cellsPerRow: CGFloat = 4
    let interItemSpacing: CGFloat = 1
    
    var lastPreviewBottomXOffset: CGFloat = 0
    var previewContainerViewTopAnchor: NSLayoutConstraint?
    var previewInitialMinY: CGFloat = 0
    
    var allowsCollectionViewPaning: Bool = false
    
    var gestureRecognizer: UIPanGestureRecognizer?
    
    var previewContainerView: UIView = {
        var view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var previewCropView: PhotoPreviewCropView = {
        let previewView = PhotoPreviewCropView(image: UIImage())
        previewView.translatesAutoresizingMaskIntoConstraints = false
        return previewView
    }()

    var spacerWithCameraButton: CameraRollHeaderView = {
        let view = CameraRollHeaderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var cameraRollCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: PhotoCollectionViewCell.identifier)
//        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = .black
        return collectionView
    }()

    //MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupNavBar()
        configureNavBarAppearence()
        spacerWithCameraButton.delegate = self
        cameraRollCollectionView.delegate = self
        cameraRollCollectionView.dataSource = self
        self.gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(dragCollectionViewHeader))
//        gestureRecognizer!.delegate = self
        self.view.backgroundColor = .black
        self.view.addGestureRecognizer(gestureRecognizer!)
        self.cameraRollCollectionView.addGestureRecognizer(self.gestureRecognizer!)
    }

    override func viewWillAppear(_ animated: Bool) {
        previewContainerViewTopAnchor?.constant = 0
        fetchUserPhotos {
            self.selectPhotoAsPreview(at: 0)
            print("Fetched photos")
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.previewInitialMinY = previewContainerView.frame.minY
        print("previewContainerView maxY: \(previewContainerView.frame.maxY)")
        print("previewContainerView minY: \(previewContainerView.frame.minY)")
    }

    // MARK: Setup methods
    override var prefersStatusBarHidden: Bool {
        return true
    }

    func configureNavBarAppearence() {
        let navigationBarAppearence = UINavigationBarAppearance()
        navigationBarAppearence.configureWithOpaqueBackground()
        navigationBarAppearence.backgroundColor = .black
        navigationBarAppearence.titleTextAttributes = [.foregroundColor: UIColor.white]
        self.navigationController?.navigationBar.standardAppearance = navigationBarAppearence
        self.navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearence
    }

    private func setupNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(dismissSelf))
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Next",
            style: .done,
            target: self,
            action: #selector(didTapNext))
        navigationItem.leftBarButtonItem?.tintColor = .white
        navigationItem.title = "New Post"
    }

    func setupViews() {
        self.view.addSubviews(previewContainerView, cameraRollCollectionView)
        self.previewContainerView.addSubviews(previewCropView, spacerWithCameraButton)
        let viewWidth = view.frame.size.width
        let spacerHeight: CGFloat = 50
        //        let previewContainerViewBottomAnchor = cameraRollHeaderCointainerView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 0)
        let previewContainerViewTopAnchor = previewContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        previewContainerViewTopAnchor.priority = .required
        self.previewContainerViewTopAnchor = previewContainerViewTopAnchor

        NSLayoutConstraint.activate([
            previewContainerViewTopAnchor,
            previewContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewContainerView.heightAnchor.constraint(equalToConstant: viewWidth + spacerHeight),
            //            previewContainerViewBottomAnchor,

            previewCropView.topAnchor.constraint(equalTo: previewContainerView.topAnchor),
            previewCropView.leadingAnchor.constraint(equalTo: previewContainerView.leadingAnchor),
            previewCropView.trailingAnchor.constraint(equalTo: previewContainerView.trailingAnchor),
            previewCropView.heightAnchor.constraint(equalToConstant: viewWidth),

            spacerWithCameraButton.topAnchor.constraint(equalTo: previewCropView.bottomAnchor),
            spacerWithCameraButton.leadingAnchor.constraint(equalTo: previewContainerView.leadingAnchor),
            spacerWithCameraButton.trailingAnchor.constraint(equalTo: previewContainerView.trailingAnchor),
            spacerWithCameraButton.bottomAnchor.constraint(equalTo: previewContainerView.bottomAnchor),

            cameraRollCollectionView.topAnchor.constraint(equalTo: previewContainerView.bottomAnchor),
            cameraRollCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraRollCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraRollCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

    }

    private func fetchUserPhotos(completion: @escaping () -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            switch status {
            case .authorized:
                print("Authorized")
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                self?.userPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                DispatchQueue.main.async {
                    self?.cameraRollCollectionView.reloadData()
                    self?.cameraRollCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0),
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
            default:
                return
            }
        }
    }

    func selectPhotoAsPreview(at path: Int, completion: @escaping () -> Void = {}) {
        let asset = userPhotos?.object(at: path)
        guard let photoWidth = asset?.pixelWidth,
              let photoHeight = asset?.pixelHeight
        else {
            return
        }
        let photoSize = CGSize(width: photoWidth, height: photoHeight)
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.version = .original
        PHCachingImageManager.default().requestImage(
            for: asset!,
            targetSize: photoSize,
            contentMode: .default,
            options: options) { image, _ in

            guard let image = image else {
                return
            }
            self.selectedPhoto = image
            completion()
        }
    }

    func focusOnPreview(withDuration: CGFloat) {
        self.previewContainerViewTopAnchor?.constant = 0
        UIView.animate(withDuration: withDuration, delay: 0, options: .curveEaseOut) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: Action methods

    @objc private func didTapNext() {
        guard let photo = previewCropView.makeCroppedImage() else {
            return
        }
        let editingVC = PhotoEditingViewController(photo: photo,
                                                   isWidthDominant: photo.isWidthDominant(),
                                                   ratio: photo.ratio())
        editingVC.delegate = self.delegate
        navigationController?.pushViewController(editingVC, animated: true)
    }

    @objc private func dismissSelf() {
        self.dismiss(animated: true)
    }

    @objc func dragCollectionViewHeader(_ pan: UIPanGestureRecognizer) {
        guard let topAnchorConstant = self.previewContainerViewTopAnchor?.constant else {
            print("Inside guard")
            return
        }
        
        
        if pan.state == .began {
            print("Pan gesture began")
            self.lastPreviewBottomXOffset = topAnchorConstant
            panEndPoint = nil
            panStartingPoint = pan.location(in: view)
            distanceDifference = pan.location(in: view).y - previewContainerView.frame.maxY
        }
        
        if pan.state == .ended {
            print("Pan gesture ended")
            self.allowsCollectionViewPaning = false
            panEndPoint = pan.location(in: view)
            panStartingPoint = nil
        }
        
        let translatedPoint = pan.translation(in: self.view)
        let currentPoint = pan.location(in: self.view)
        print("TranslatedPointY: \(translatedPoint.y)")
        handleCollectionViewPaning(for: currentPoint, translatedPoint: translatedPoint)

//        if cameraRollHeaderCointainerView.frame.contains(location) {
//            let translation = pan.translation(in: self.view)
//                self.previewContainerViewTopAnchor?.constant = (self.lastPreviewBottomXOffset + translation.y)
//                        cameraRollHeaderCointainerView.transform = CGAffineTransform(translationX: 0, y: bottomCoordinate + translation.y)
//        }
    }
    
    private func handleCollectionViewPaning(for currentPoint: CGPoint, translatedPoint: CGPoint) {
        guard var startingPoint = self.panStartingPoint,
              let distanceDifference = self.distanceDifference
        else {
            return
        }
        
        if currentPoint.y <= (previewContainerView.frame.maxY - 100) {
            self.allowsCollectionViewPaning = true
        }
        print("START")
        print("Inital touch point before translation: \(startingPoint.y)")
        let translation = translatedPoint.y + distanceDifference
//        startingPoint.y += translation
        print("Inital touch point after translation: \(startingPoint.y)")
        var containsStartingPoint = cameraRollCollectionView.frame.contains(startingPoint)
        var containsCurrentPoint = previewContainerView.frame.contains(currentPoint)
        var notOutOfBounds = previewContainerView.frame.maxY >= 150 && previewContainerView.frame.minY <= previewInitialMinY
        
        print("\npreviewContainer current minY \(previewContainerView.frame.minY)")
        print("previewContainer initial minY \(previewInitialMinY)")
        
        print("\nhandling paning")
        print("Finger point: \(currentPoint.y)")
        print("\ncollectionView containts initial touch Point: \(containsStartingPoint)")
        print("CameraRoll header contains finger point: \(containsCurrentPoint)")
        print("NotOutOfBounds: \(notOutOfBounds)")
        print("\nCollectionView minY: \(cameraRollCollectionView.frame.minY)")
        print("CollectionView maxY: \(cameraRollCollectionView.frame.maxY)")
        
        if  containsCurrentPoint && containsStartingPoint && notOutOfBounds && allowsCollectionViewPaning {
            print("Inside if")
            print("Translation with distance difference: \(translation)")
            self.previewContainerViewTopAnchor?.constant = ((self.lastPreviewBottomXOffset + translation) + 100)
        } else {

        }
        print("END")
    }
}

// MARK: CollectionView delegate
extension CameraRollViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.gestureRecognizer {
            return false
        } else {
            return true
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let photos = userPhotos else {
            return 0
        }
        print("Photos count: \(photos.count)")
        return photos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier,
                                                            for: indexPath) as? PhotoCollectionViewCell
        else {
            fatalError("Could not cast cell")
        }
        let asset = userPhotos?.object(at: indexPath.row)
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isSynchronous = true
        PHCachingImageManager.default().requestImage(for: asset!,
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

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectPhotoAsPreview(at: indexPath.row) {
        }
    }

    // MARK: Collection View Layout Setup

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = interItemSpacing * (cellsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / cellsPerRow

        return CGSize(width: widthPerItem, height: widthPerItem)

    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return interItemSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return interItemSpacing
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

//extension CameraRollViewController: UIGestureRecognizerDelegate {
//    
//
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
////        if gestureRecognizer.view == cameraRollCollectionView && otherGestureRecognizer == self.gestureRecognizer {
////            print("Should recognize simultaneously")
////            return true
////        }
//        
//        if gestureRecognizer == self.gestureRecognizer || otherGestureRecognizer == self.gestureRecognizer {
//            print("\nshouldRecognizeSimultaneouslyWith")
//            return true
//        }
//        return false
//    }
//
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
////        if gestureRecognizer == self.cameraRollCollectionView.panGestureRecognizer && otherGestureRecognizer == self.gestureRecognizer {
////            print("should be required to fail is true")
////            return true
////        }
////        return false
//
//        if otherGestureRecognizer == self.gestureRecognizer {
//            print("\nshouldBeRequiredToFailBy")
//            return true
//        }
//        
//        return false
//    }
//
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        if gestureRecognizer == self.gestureRecognizer {
//                print("\nshouldRequireFailureOf")
//                return true
//            }
//        return false
//    }
//}
