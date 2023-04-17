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
                self.focusOnPreview(withDuration: 0.1)
            }
        }
    }
    
    var userPhotos: PHFetchResult<PHAsset>?
    let cellsPerRow: CGFloat = 4
    let interItemSpacing: CGFloat = 1
    var lastPreviewBottomXOffset: CGFloat = 0
    var previewContainerViewTopAnchor: NSLayoutConstraint?
    var scrollBeginningPosition: CGFloat = 0
    var gestureRecognizer: UIPanGestureRecognizer?
    
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
    
    var cameraRollHeaderCointainerView: UIView = {
        var view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var cameraRollCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: PhotoCollectionViewCell.identifier)
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
        gestureRecognizer!.delegate = self
        self.view.backgroundColor = .black
        self.previewCropView.addGestureRecognizer(gestureRecognizer!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchUserPhotos {
            self.selectPhotoAsPreview(at: 0)
            print("Fetched photos")
        }
        
    }
    
    //MARK: Setup methods
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
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(dismissSelf))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(didTapNext))
        navigationItem.leftBarButtonItem?.tintColor = .white
        self.title = "New Post"
    }
    
    func setupViews() {
        self.view.addSubviews(cameraRollHeaderCointainerView, cameraRollCollectionView)
        self.cameraRollHeaderCointainerView.addSubviews(previewCropView, spacerWithCameraButton)
        let viewWidth = view.frame.size.width
        let spacerHeight: CGFloat = 50
        //        let previewContainerViewBottomAnchor = cameraRollHeaderCointainerView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 0)
        let previewContainerViewTopAnchor = cameraRollHeaderCointainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        previewContainerViewTopAnchor.priority = .required
        self.previewContainerViewTopAnchor = previewContainerViewTopAnchor
        
        NSLayoutConstraint.activate([
            previewContainerViewTopAnchor,
            cameraRollHeaderCointainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraRollHeaderCointainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraRollHeaderCointainerView.heightAnchor.constraint(equalToConstant: viewWidth + spacerHeight),
            //            previewContainerViewBottomAnchor,
            
            previewCropView.topAnchor.constraint(equalTo: cameraRollHeaderCointainerView.topAnchor),
            previewCropView.leadingAnchor.constraint(equalTo: cameraRollHeaderCointainerView.leadingAnchor),
            previewCropView.trailingAnchor.constraint(equalTo: cameraRollHeaderCointainerView.trailingAnchor),
            previewCropView.heightAnchor.constraint(equalToConstant: viewWidth),
            
            spacerWithCameraButton.topAnchor.constraint(equalTo: previewCropView.bottomAnchor),
            spacerWithCameraButton.leadingAnchor.constraint(equalTo: cameraRollHeaderCointainerView.leadingAnchor),
            spacerWithCameraButton.trailingAnchor.constraint(equalTo: cameraRollHeaderCointainerView.trailingAnchor),
            spacerWithCameraButton.bottomAnchor.constraint(equalTo: cameraRollHeaderCointainerView.bottomAnchor),
            
            cameraRollCollectionView.topAnchor.constraint(equalTo: cameraRollHeaderCointainerView.bottomAnchor),
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
                print("Photos in library", self?.userPhotos?.count)
                DispatchQueue.main.async {
                    self?.cameraRollCollectionView.reloadData()
                    self?.cameraRollCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
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
    
    func selectPhotoAsPreview(at path: Int, completion: @escaping () -> Void = {}) {
        let asset = userPhotos?.object(at: path)
        let photoSize = CGSize(width: view.frame.width, height: view.frame.width)
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        
        PHCachingImageManager.default().requestImage(for: asset!, targetSize: photoSize, contentMode: .aspectFill, options: options) { image, _ in
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
    
    //MARK: Action methods
    
    @objc private func didTapNext() {
        guard let photo = previewCropView.makeCroppedImage() else {
            return
        }
        let editingVC = PhotoEditingViewController(photo: photo, isWidthDominant: photo.isWidthDominant(), ratio: photo.ratio())
        navigationController?.pushViewController(editingVC, animated: true)
    }
    
    @objc private func dismissSelf() {
        self.dismiss(animated: true)
    }
    
    @objc func dragCollectionViewHeader(_ pan: UIPanGestureRecognizer) {
        guard let topAnchorConstant = self.previewContainerViewTopAnchor?.constant else {
            return
        }
        
        if pan.state == .began {
            self.lastPreviewBottomXOffset = topAnchorConstant
        }
        
        let location = pan.location(in: self.view)
        
        if cameraRollHeaderCointainerView.frame.contains(location) {
            let translation = pan.translation(in: self.view)
            if (topAnchorConstant + translation.y) <= 0 {
                self.previewContainerViewTopAnchor?.constant = (self.lastPreviewBottomXOffset + translation.y)
            }
            //            cameraRollHeaderCointainerView.transform = CGAffineTransform(translationX: 0, y: bottomCoordinate + translation.y)
        }
        
        
        
    }
    
    
}

//MARK: CollectionView delegate
extension CameraRollViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let photos = userPhotos else {
            return 0
        }
        print("Photos count: \(photos.count)")
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as! PhotoCollectionViewCell
        let asset = userPhotos?.object(at: indexPath.row)
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isSynchronous = true
        PHCachingImageManager.default().requestImage(for: asset!, targetSize: cell.frame.size, contentMode: .aspectFill, options: options) { image, _ in
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
    
    //Collection View Layout Setup
    
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
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

extension CameraRollViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view != otherGestureRecognizer.view {
            return false
        }

        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        if gestureRecognizer == self.cameraRollCollectionView.panGestureRecognizer && otherGestureRecognizer == self.gestureRecognizer {
//            print("should be required to fail is true")
//            return true
//        }
//        return false
        
        if otherGestureRecognizer == self.gestureRecognizer {
            print("Returning true")
            return true
        }
        
        return false
    }
    
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        print("content offset is \(self.cameraRollCollectionView.contentOffset.y)")
//        if self.cameraRollCollectionView.contentOffset.y <= 0 {
//            print("inside shouldRequireFailureOf")
//            if gestureRecognizer == self.gestureRecognizer  && otherGestureRecognizer ==  cameraRollCollectionView.panGestureRecognizer {
//                print("returning true")
//                return true
//            }
//        }
//        return false
//    }
    
    
}

extension CameraRollViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let distanceScrolled = scrollView.panGestureRecognizer.location(in: self.view).y - self.scrollBeginningPosition
        print(distanceScrolled)
        if scrollView.contentOffset.y <= 0 && scrollView.isDragging {
            self.previewContainerViewTopAnchor?.constant += 1
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.scrollBeginningPosition = scrollView.panGestureRecognizer.location(in: self.view).y
    }
    
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let distanceScrolled = scrollView.panGestureRecognizer.location(in: self.view).y - self.scrollBeginningPosition
        
        if scrollView.contentOffset.y <= 0 && distanceScrolled >= 150 {
            self.focusOnPreview(withDuration: 0.4)
        }
    }
    
}
