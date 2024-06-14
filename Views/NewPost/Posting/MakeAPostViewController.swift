//
//  MakeAPostViewController.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 14.10.2022.
//

import UIKit

@MainActor protocol NewPostProtocol: AnyObject {
    func makeANewPost(post: UserPost)
}

class MakeAPostViewController: UIViewController {

    let viewModel: NewPostViewModel

    weak var delegate: NewPostProtocol?

    let captionTextViewPlaceholder = String(localized: "Add caption...")
    let captionColor = UIColor.gray

    private lazy var postImagePreview: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var separatorLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .darkGray
        return view
    }()

    private lazy var captionTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.clipsToBounds = true
        textView.textContainerInset = UIEdgeInsets(top: 15, left: 10, bottom: 10, right: 10)
        textView.font = CustomFonts.regularFont(ofSize: 15)
        textView.textColor = captionColor
        textView.backgroundColor = .black
        textView.isScrollEnabled = false
        return textView
    }()

    private lazy var postButton: UIButton = {
        let button = UIButton()
        button.setTitle(String(localized: "Post"), for: .normal)
        button.titleLabel?.font = CustomFonts.boldFont(ofSize: 17)
        button.setTitleColor(.systemBlue, for: .normal)
        button.addTarget(self, action: #selector(postAPhoto), for: .touchUpInside)
        return button
    }()

    init(photo: UIImage) {

        self.viewModel = NewPostViewModel(photo: photo)
        super.init(nibName: nil, bundle: nil)
        if let data = photo.jpegData(compressionQuality: 1) {
            print("Image data count on posting: ", data.count)
        }
        self.postImagePreview.image = photo
        self.captionTextView.text = self.captionTextViewPlaceholder
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubviews(postImagePreview, separatorLine, captionTextView)
        setupNavBar()
        setupConstraints()
        setupEdditingInteruptionGestures()
        captionTextView.delegate = self
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    @objc func hideKeyboard() {
        captionTextView.endEditing(true)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            postImagePreview.topAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor),
            postImagePreview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            postImagePreview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            postImagePreview.heightAnchor.constraint(equalTo: view.widthAnchor),

            separatorLine.topAnchor.constraint(equalTo: postImagePreview.bottomAnchor, constant: 40),
            separatorLine.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            separatorLine.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),

            captionTextView.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 5),
            captionTextView.leadingAnchor.constraint(equalTo: postImagePreview.leadingAnchor),
            captionTextView.trailingAnchor.constraint(equalTo: postImagePreview.trailingAnchor),
            captionTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            captionTextView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -15)
        ])
    }

    private func setupNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"),
            style: .plain,
            target: self,
            action: #selector(navigateBack))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: postButton)
        navigationItem.leftBarButtonItem?.tintColor = .white
    }

   @objc func postAPhoto() {
       print("Post button tapped")
       showLoadingIndicator()
       viewModel.prepareForPosting { newPost in
           DispatchQueue.main.async {
               self.delegate?.makeANewPost(post: newPost)
           }
       }
    }

    @objc private func navigateBack() {
        navigationController?.popViewController(animated: true)
    }

    func showAlert() {
        let alertController = UIAlertController()
        alertController.title = String(localized: "Unable to make a post")
        alertController.message = String(localized: "There was a network error, please try again later")

        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }

    func showLoadingIndicator() {
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.color = .white
        loadingIndicator.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        loadingIndicator.alpha = 0
        loadingIndicator.startAnimating()

        UIView.animate(withDuration: 0.2) {
            self.postButton.alpha = 0
        } completion: { _ in
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingIndicator)
            UIView.animate(withDuration: 0.2) {
                loadingIndicator.alpha = 1
                loadingIndicator.transform = .identity
            }
        }
    }

}

extension MakeAPostViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == captionColor {
            textView.text = nil
            textView.textColor = .white
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = self.captionTextViewPlaceholder
            textView.textColor = captionColor
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        self.viewModel.post.caption = textView.text
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        return numberOfChars <= 300
    }
}
