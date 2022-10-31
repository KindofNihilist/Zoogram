//
//  MakeAPostViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 14.10.2022.
//

import UIKit

class MakeAPostViewController: UIViewController {
    
    let viewModel = NewPostViewModel()
    
    let postImagePreview: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let captionTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 5, bottom: 0, right: 5)
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.textColor = .placeholderText
        textView.text = "Write a caption..."
        return textView
    }()
    
    init(photo: UIImage) {
        super.init(nibName: nil, bundle: nil)
        self.postImagePreview.image = photo
        self.viewModel.preparePhotoForPosting(photoToCompress: photo)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        captionTextView.delegate = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Post", style: .plain, target: self, action: #selector(postAPhoto))
        
        view.addSubviews(postImagePreview, captionTextView)
        setupConstraints()
        
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            postImagePreview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            postImagePreview.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            postImagePreview.heightAnchor.constraint(equalToConstant: 100),
            postImagePreview.widthAnchor.constraint(equalToConstant: 100),
            
            captionTextView.topAnchor.constraint(equalTo: postImagePreview.topAnchor),
            captionTextView.leadingAnchor.constraint(equalTo: postImagePreview.trailingAnchor, constant: 5),
            captionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            captionTextView.bottomAnchor.constraint(equalTo: postImagePreview.bottomAnchor, constant: 15)
        ])
    }
    
   @objc func postAPhoto() {
       print("pressed post")
       viewModel.makeAPost(postType: .photo, caption: captionTextView.text) { isSuccesfull in
           if isSuccesfull {
               print("Made a post")
               self.view.window?.rootViewController?.dismiss(animated: true)
           } else {
               self.showAlert()
           }
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
            textView.text = "Write a caption..."
            textView.textColor = .placeholderText
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        return numberOfChars < 720
    }
}
