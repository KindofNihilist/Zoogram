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
    var inputViewHeight: CGFloat = 0
    let textViewMaxLinesCount = 11
    var numberOfLines = 1
    let textViewCharacterLimit = 300
    var charactersLeft = 300
    let placeholder = String(localized: "Enter comment")

    private lazy var postButtonBottomConstraint = postButton.bottomAnchor.constraint(equalTo: commentTextView.bottomAnchor, constant: -5)
    private lazy var postButtonCenterYConstraint = postButton.centerYAnchor.constraint(equalTo: userProfilePicture.centerYAnchor)
    private lazy var postButtonTrailingConstraint = postButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -3)

    private var separator: UIView = {
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = Colors.detailGray
        return separator
    }()

     var userProfilePicture: ProfilePictureImageView = {
        let imageView = ProfilePictureImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private var inputContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 0.8
        view.layer.borderColor = Colors.detailGray.cgColor
        view.backgroundColor = Colors.backgroundSecondary
        return view
    }()

    private var commentTextView: VerticallyCenteredTextView = {
        let textView = VerticallyCenteredTextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = Colors.backgroundSecondary
        textView.font = CustomFonts.regularFont(ofSize: 16)
        textView.clipsToBounds = true
        textView.layer.masksToBounds = true
        textView.isScrollEnabled = false
        return textView
    }()

    private var placeholderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = CustomFonts.regularFont(ofSize: 16)
        label.sizeToFit()
        label.textColor = .placeholderText
        return label
    }()

    private var charLimitLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        label.font = CustomFonts.boldFont(ofSize: 14)
        label.alpha = 0
        return label
    }()

    private lazy var postButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true
        button.layer.cornerRadius = 30/2
        button.setImage(UIImage(systemName: "arrow.up.circle.fill",
                                withConfiguration: UIImage.SymbolConfiguration(pointSize: 35)), for: .normal)
        button.tintColor = Colors.coolBlue
        button.addTarget(self, action: #selector(didTapPostButton), for: .touchUpInside)
        return button
    }()

    override init(frame: CGRect, inputViewStyle: UIInputView.Style) {
        super.init(frame: frame, inputViewStyle: inputViewStyle)
        autoresizingMask = .flexibleHeight
        backgroundColor = Colors.background
        setupConstraints()
        placeholderLabel.text = placeholder
        commentTextView.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setViewCornerRadius()
    }

    override var intrinsicContentSize: CGSize {
        if commentTextView.isScrollEnabled {
            return CGSizeMake(UIView.noIntrinsicMetric, inputViewHeight)
        } else {
            return .zero
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        inputContainerView.layer.borderColor = Colors.detailGray.cgColor
    }

    func configure(with profilePhoto: UIImage?) {
        self.userProfilePicture.image = profilePhoto
    }

    func setViewCornerRadius() {
        userProfilePicture.layer.cornerRadius = elementsHeight / 2
        inputContainerView.layer.cornerRadius = elementsHeight / 2
    }
   private func setupConstraints() {
       self.addSubviews(separator, userProfilePicture, inputContainerView)
        inputContainerView.addSubviews(commentTextView, postButton, placeholderLabel, charLimitLabel)

        NSLayoutConstraint.activate([

//            separator.topAnchor.constraint(equalTo: self.topAnchor),
//            separator.heightAnchor.constraint(equalToConstant: 1),
//            separator.widthAnchor.constraint(equalTo: self.widthAnchor),

            userProfilePicture.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10),
            userProfilePicture.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            userProfilePicture.widthAnchor.constraint(equalToConstant: elementsHeight),
            userProfilePicture.heightAnchor.constraint(equalToConstant: elementsHeight),

            inputContainerView.leadingAnchor.constraint(equalTo: userProfilePicture.trailingAnchor, constant: 10),
            inputContainerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10),
            inputContainerView.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            inputContainerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),

            commentTextView.topAnchor.constraint(equalTo: inputContainerView.topAnchor),
            commentTextView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 10),
            commentTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor),
            commentTextView.trailingAnchor.constraint(equalTo: postButton.leadingAnchor),
            commentTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: elementsHeight),

            placeholderLabel.leadingAnchor.constraint(equalTo: commentTextView.leadingAnchor, constant: 5),
            placeholderLabel.centerYAnchor.constraint(equalTo: commentTextView.centerYAnchor),

            postButtonTrailingConstraint,
            postButtonCenterYConstraint,
            postButton.widthAnchor.constraint(equalToConstant: elementsHeight - 3),
            postButton.heightAnchor.constraint(equalToConstant: elementsHeight - 3),

            charLimitLabel.bottomAnchor.constraint(equalTo: postButton.topAnchor),
            charLimitLabel.centerXAnchor.constraint(equalTo: postButton.centerXAnchor)
        ])
    }

    @objc func didTapPostButton() {
        guard let text = commentTextView.text, text != placeholder, text != "" else {
            return
        }
        delegate?.postButtonTapped(commentText: text) {
            self.commentTextView.text.removeAll()
            self.numberOfLines = self.commentTextView.numberOfLines()
            self.handleLinesCount()
            self.handlePlaceholder(for: self.commentTextView)
            self.layoutPostButton()
        }
    }

    private func handlePlaceholder(for textView: UITextView) {
        if textView.text.isEmpty {
            placeholderLabel.isHidden = false
        } else {
            placeholderLabel.isHidden = true
        }
    }

    private func handleCharacterLimit(for textView: UITextView) {
        if charactersLeft == 50 {
            UIView.animate(withDuration: 0.3) {
                self.charLimitLabel.alpha = 1
            }
        } else if charactersLeft > 50 {
            UIView.animate(withDuration: 0.3) {
                self.charLimitLabel.alpha = 0
            }
        }

        guard charactersLeft <= 50 else {
            return
        }
        charLimitLabel.text = "\(charactersLeft)"
        if charactersLeft < 0 {
            UIView.animate(withDuration: 0.3) {
                self.charLimitLabel.textColor = .systemRed
                self.formatTextPastCharacterLimit(in: textView)
            }
        } else if charactersLeft <= 30 {
            charLimitLabel.textColor = .systemYellow
        } else {
            charLimitLabel.textColor = .systemGreen
        }
    }

    private func handleLinesCount() {
        if numberOfLines > textViewMaxLinesCount {
            self.inputViewHeight = self.frame.height
            commentTextView.isScrollEnabled = true
            self.invalidateIntrinsicContentSize()

        } else if commentTextView.isScrollEnabled && numberOfLines <= textViewMaxLinesCount {
            commentTextView.isScrollEnabled = false
            self.invalidateIntrinsicContentSize()
        }
    }

    private func handlePostButton() {
        if charactersLeft < 0 {
            UIView.animate(withDuration: 0.3) {
                self.postButton.isEnabled = false
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.postButton.isEnabled = true
            }
        }
    }

    private func layoutPostButton() {
        if  numberOfLines > 1 {
            postButtonTrailingConstraint.constant = -5
            postButtonCenterYConstraint.isActive = false
            postButtonBottomConstraint.isActive = true
        } else if numberOfLines == 1 {
            postButtonTrailingConstraint.constant = -3
            postButtonBottomConstraint.isActive = false
            postButtonCenterYConstraint.isActive = true
        }
        self.setNeedsLayout()
        UIView.animate(withDuration: 0.3) {
            self.superview?.layoutIfNeeded()
        }
    }

    private func formatTextPastCharacterLimit(in textView: UITextView) {
        let extraCharactersCount = abs(charactersLeft)
        let excessiveTextColor = UIColor.systemRed.withAlphaComponent(0.5)

        let fittingText = NSAttributedString(string: String(textView.text.prefix(textViewCharacterLimit)), 
                                             attributes: [.font: commentTextView.font])

        var textPastTheLimit = NSAttributedString(string: String(textView.text.suffix(extraCharactersCount)), 
                                                  attributes: [.backgroundColor: excessiveTextColor, .font: commentTextView.font])

        let wholeAttributedText = NSMutableAttributedString()
        wholeAttributedText.append(fittingText)
        wholeAttributedText.append(textPastTheLimit)
        textView.attributedText = wholeAttributedText
    }
}

extension CommentAccessoryView: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        numberOfLines = commentTextView.numberOfLines()
        charactersLeft = textViewCharacterLimit - textView.text.count
        handleCharacterLimit(for: textView)
        handlePlaceholder(for: textView)
        layoutPostButton()
        handlePostButton()
        handleLinesCount()
    }
}
