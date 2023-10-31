//
//  MakeAPostViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 14.10.2022.
//

import UIKit

protocol NewPostProtocol: AnyObject {
    func makeANewPost(post: UserPost, completion: @escaping () -> Void)
}

class MakeAPostViewController: UIViewController {

    let viewModel: NewPostViewModel

    weak var delegate: NewPostProtocol?

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
        textView.font = CustomFonts.regularFont(ofSize: 17)
        textView.textColor = .placeholderText
        return textView
    }()

    init(photo: UIImage) {
        self.viewModel = NewPostViewModel()
        super.init(nibName: nil, bundle: nil)
        self.viewModel.preparePhotoForPosting(photoToCompress: photo)
        self.postImagePreview.image = photo
        self.captionTextView.text = self.captionTextViewPlaceholder
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillAppear),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillDissappear),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
          tapGesture.cancelsTouchesInView = true
        view.addGestureRecognizer(tapGesture)
        view.backgroundColor = .systemBackground
        view.addSubviews(postImagePreview, captionTextView)
        setupNavBar()
        setupConstraints()
        setupPreview()
        captionTextView.delegate = self
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

            captionTextView.heightAnchor.constraint(equalToConstant: 200),
            captionTextView.leadingAnchor.constraint(equalTo: postImagePreview.leadingAnchor),
            captionTextView.trailingAnchor.constraint(equalTo: postImagePreview.trailingAnchor),
            captionTextView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -15)
        ])
    }

    private func setupNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"),
            style: .plain,
            target: self,
            action: #selector(navigateBack))

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Post",
            style: .done,
            target: self,
            action: #selector(postAPhoto))

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
        let heightConstraint = NSLayoutConstraint(
            item: postImagePreview,
            attribute: NSLayoutConstraint.Attribute.height,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: postImagePreview,
            attribute: NSLayoutConstraint.Attribute.width,
            multiplier: imageAspectRatio,
            constant: 0)
        self.imagePreviewHeightConstraint = heightConstraint
        self.imagePreviewHeightConstraint.isActive = true
    }

   @objc func postAPhoto() {
       guard viewModel.post.image != nil else {
           return
       }
       viewModel.post.caption = viewModel.post.caption?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
       delegate?.makeANewPost(post: viewModel.post) {
//           self.dismiss(animated: true)
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

    func textViewDidChange(_ textView: UITextView) {
        self.viewModel.post.caption = textView.text
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        return numberOfChars < 720
    }
}
