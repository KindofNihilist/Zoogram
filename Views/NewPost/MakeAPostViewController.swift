//
//  MakeAPostViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 14.10.2022.
//

import UIKit

class MakeAPostViewController: UIViewController {
    
    let viewModel = NewPostViewModel()
    
    let captionTextViewPlaceholder = "Write a caption..."
    
    var imagePreviewHeightConstraint = NSLayoutConstraint()
    
    let postImagePreview: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .systemCyan
        return imageView
    }()
    
    let captionTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.clipsToBounds = true
        textView.layer.cornerRadius = 15
        textView.layer.shadowColor = UIColor.black.cgColor
        textView.layer.shadowOffset = CGSize(width: 0, height: 0)
        textView.layer.masksToBounds = false
        textView.layer.shadowOpacity = 0.2
        textView.layer.shadowRadius = 5
        textView.textContainerInset = UIEdgeInsets(top: 15, left: 10, bottom: 10, right: 10)
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.textColor = .placeholderText
        return textView
    }()
    
    init(photo: UIImage) {
        super.init(nibName: nil, bundle: nil)
        self.postImagePreview.image = photo
        self.viewModel.preparePhotoForPosting(photoToCompress: photo)
        self.captionTextView.text = self.captionTextViewPlaceholder
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        viewModel.getSnapshotOfFollowers()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDissappear), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavBar()
        captionTextView.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
          tapGesture.cancelsTouchesInView = true
        view.addGestureRecognizer(tapGesture)
        view.addSubviews(postImagePreview, captionTextView)
        setupConstraints()
        setupPreview()
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc func hideKeyboard() {
        captionTextView.endEditing(true)
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            postImagePreview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            postImagePreview.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            postImagePreview.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            
//            captionTextView.topAnchor.constraint(equalTo: postImagePreview.bottomAnchor, constant: 20),
            captionTextView.heightAnchor.constraint(equalToConstant: 200),
            captionTextView.leadingAnchor.constraint(equalTo: postImagePreview.leadingAnchor),
            captionTextView.trailingAnchor.constraint(equalTo: postImagePreview.trailingAnchor),
            captionTextView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -15),
        ])
    }
    
    private func setupNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(navigateBack))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Post", style: .done, target: self, action: #selector(postAPhoto))
        navigationItem.leftBarButtonItem?.tintColor = .white
        let button = UIButton()
        button.tintColor = .white
        navigationItem.titleView = button
    }
    
    func setupPreview() {
        guard let photo = postImagePreview.image else {
            return
        }
        
        let imageAspectRatio = photo.size.height / photo.size.width
        let heightConstraint = NSLayoutConstraint(item: postImagePreview, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: postImagePreview, attribute: NSLayoutConstraint.Attribute.width, multiplier: imageAspectRatio, constant: 0)
        self.imagePreviewHeightConstraint = heightConstraint
        self.imagePreviewHeightConstraint.isActive = true
    }
    
   @objc func postAPhoto() {
       var caption = ""
       if captionTextView.text != captionTextViewPlaceholder {
           caption = captionTextView.text
       }
       viewModel.makeAPost(caption: caption) { isSuccesfull in
           if isSuccesfull {
               print("Made a post")
               self.view.window?.rootViewController?.dismiss(animated: true)
           } else {
               self.showAlert()
           }
       }
    }
    
    @objc private func navigateBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func keyboardWillAppear() {
        UIView.animate(withDuration: 0.2, delay: 0) {
            self.postImagePreview.alpha = 0
        }
    }
    
    @objc private func keyboardWillDissappear() {
        UIView.animate(withDuration: 0.2, delay: 0) {
            self.postImagePreview.alpha = 1
        }
    }
    
    func showAlert() {
        let alertController = UIAlertController()
        alertController.title = "Unable to make a post"
        alertController.message = "There was a network error, please try again later"
        
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        
        present(alertController, animated: true)
    }

}

extension MakeAPostViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = nil
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = self.captionTextViewPlaceholder
            textView.textColor = .placeholderText
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        return numberOfChars < 720
    }
}
