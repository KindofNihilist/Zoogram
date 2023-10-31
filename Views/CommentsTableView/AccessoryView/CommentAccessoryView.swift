//
//  CommentsAccessoryView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.01.2023.
//

import UIKit

protocol CommentAccessoryViewProtocol: AnyObject {
    func postButtonTapped(commentText: String, completion: @escaping () -> Void)
}

class CommentAccessoryView: UIInputView {

    weak var delegate: CommentAccessoryViewProtocol?

    var isEditing: Bool = false
    let elementsHeight: CGFloat = 40
    let textViewMaxHeight: CGFloat = 100
    let placeholder = "Enter comment"

     var intrinsicHeight: CGFloat = 0 {
        didSet {
            print("Intrinsic height set to:", intrinsicHeight)
            animateHeightChange()
        }
    }

     var accessoryViewHeight: CGFloat = 50

    private var separator: UIView = {
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = ColorScheme.separatorColor
        return separator
    }()

     var userProfilePicture: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private var inputContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.backgroundColor = .systemGreen
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.placeholderText.cgColor
        return view
    }()

    private var commentTextView: VerticallyCenteredTextView = {
        let textView = VerticallyCenteredTextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .systemRed
        textView.font = CustomFonts.regularFont(ofSize: 16)
        textView.clipsToBounds = true
        textView.isScrollEnabled = false
        return textView
    }()

    private lazy var postButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true
        button.layer.cornerRadius = 30/2
        button.setImage(UIImage(systemName: "arrow.up.circle.fill",
                                withConfiguration: UIImage.SymbolConfiguration(pointSize: 35)), for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(self, action: #selector(didTapPostButton), for: .touchUpInside)
        return button
    }()

    override init(frame: CGRect, inputViewStyle: UIInputView.Style) {
        super.init(frame: frame, inputViewStyle: inputViewStyle)
        setupConstraints()
        backgroundColor = .systemBackground
        commentTextView.delegate = self
        commentTextView.text = placeholder
        commentTextView.textColor = .placeholderText
        autoresizingMask = .flexibleHeight
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        setViewCornerRadius()
    }

    func configure(with profilePhoto: UIImage?) {
        self.userProfilePicture.image = profilePhoto
    }

    func animateHeightChange() {
        var duration: Double = 0.6
        if self.intrinsicHeight > 50 {
            duration = 0
        }
        self.invalidateIntrinsicContentSize()
        self.superview?.setNeedsLayout()

        UIView.animate(withDuration: duration, delay: 0) {
            print("inside animation block")
            self.superview?.layoutIfNeeded()
        }
    }

    func setViewCornerRadius() {
        userProfilePicture.layer.cornerRadius = elementsHeight / 2
        inputContainerView.layer.cornerRadius = elementsHeight / 2
    }
   private func setupConstraints() {
       self.addSubviews(separator, userProfilePicture, inputContainerView)
        inputContainerView.addSubviews(commentTextView, postButton)

        NSLayoutConstraint.activate([

            separator.topAnchor.constraint(equalTo: self.topAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
            separator.widthAnchor.constraint(equalTo: self.widthAnchor),
            separator.bottomAnchor.constraint(equalTo: userProfilePicture.topAnchor, constant: -10),

            userProfilePicture.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10),
            userProfilePicture.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            userProfilePicture.widthAnchor.constraint(equalToConstant: elementsHeight),
            userProfilePicture.heightAnchor.constraint(equalToConstant: elementsHeight),

            inputContainerView.leadingAnchor.constraint(equalTo: userProfilePicture.trailingAnchor, constant: 10),
            inputContainerView.bottomAnchor.constraint(equalTo: userProfilePicture.bottomAnchor),
            inputContainerView.topAnchor.constraint(equalTo: userProfilePicture.topAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),

            commentTextView.topAnchor.constraint(equalTo: inputContainerView.topAnchor),
            commentTextView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 10),
            commentTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor),
            commentTextView.trailingAnchor.constraint(equalTo: postButton.leadingAnchor),

            postButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -3),
            postButton.centerYAnchor.constraint(equalTo: userProfilePicture.centerYAnchor),
            postButton.widthAnchor.constraint(equalToConstant: elementsHeight - 3),
            postButton.heightAnchor.constraint(equalToConstant: elementsHeight - 3)
        ])
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: self.intrinsicHeight)
    }

    @objc func didTapPostButton() {
        guard let text = commentTextView.text, text != placeholder, text != "" else {
            return
        }
        delegate?.postButtonTapped(commentText: text) {
            self.commentTextView.text = ""
            self.sizeTextViewToItsContent(textView: self.commentTextView)
        }
    }
}

extension CommentAccessoryView: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        self.isEditing = true
        if textView.text == placeholder {
            textView.text = ""
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        isEditing = false
        guard textView.text != "" else {
            textView.text = placeholder
            textView.textColor = .placeholderText
            return
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        sizeTextViewToItsContent(textView: textView)
    }

    func sizeTextViewToItsContent(textView: UITextView) {
        let size = CGSize(width: frame.size.width, height: .infinity)
        let estimatedSize = textView.sizeThatFits(size)

        if estimatedSize.height > textViewMaxHeight {
            print("estimated size > max height enabling scrolling")
            commentTextView.isScrollEnabled = true
        } else if estimatedSize.height > 40 {
            self.intrinsicHeight = estimatedSize.height
            self.accessoryViewHeight = intrinsicHeight
        } else if estimatedSize.height < 40 {
            commentTextView.isScrollEnabled = false
            self.intrinsicHeight = 50
            self.accessoryViewHeight = 50
        }
    }
}
