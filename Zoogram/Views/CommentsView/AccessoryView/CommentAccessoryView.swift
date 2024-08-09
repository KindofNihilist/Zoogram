//
//  CommentsAccessoryView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 28.01.2023.
//
import UIKit

@MainActor protocol CommentAccessoryViewProtocol: AnyObject {
    func sendButtonTapped(commentText: String)
}

class CommentAccessoryView: UIView {

    weak var delegate: CommentAccessoryViewProtocol?

    var isEditing: Bool = false
    let elementsHeight: CGFloat = 40
    var inputViewHeight: CGFloat = 0
    let textViewMaxLinesCount = 11
    var numberOfLines = 1
    let textViewCharacterLimit = 300
    var charactersLeft = 300
    let placeholder = String(localized: "Enter comment")

    private var postButtonBottomConstraint: NSLayoutConstraint!
    private var postButtonCenterYConstraint: NSLayoutConstraint!
    private var postButtonTrailingConstraint: NSLayoutConstraint!

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

    private lazy var sendButton: SendButton = {
        let button = SendButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        view.isHidden = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        autoresizingMask = .flexibleHeight
        backgroundColor = Colors.background
        setupConstraints()
        placeholderLabel.text = placeholder
        commentTextView.delegate = self
        sendButton.action = { [weak self] in
            self?.didTapSendButton()
        }
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
            return CGSize(width: UIView.noIntrinsicMetric, height: inputViewHeight)
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

    func resign() {
        commentTextView.resignFirstResponder()
    }
    
   private func setupConstraints() {
       self.addSubviews(userProfilePicture, inputContainerView)
       inputContainerView.addSubviews(commentTextView, sendButton, placeholderLabel, charLimitLabel, loadingIndicator)

       postButtonBottomConstraint = sendButton.bottomAnchor.constraint(equalTo: commentTextView.bottomAnchor, constant: -5)
       postButtonCenterYConstraint = sendButton.centerYAnchor.constraint(equalTo: userProfilePicture.centerYAnchor)
       postButtonTrailingConstraint = sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -3)

        NSLayoutConstraint.activate([
            userProfilePicture.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10),
            userProfilePicture.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
            userProfilePicture.widthAnchor.constraint(equalToConstant: elementsHeight),
            userProfilePicture.heightAnchor.constraint(equalToConstant: elementsHeight),

            inputContainerView.leadingAnchor.constraint(equalTo: userProfilePicture.trailingAnchor, constant: 10),
            inputContainerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10),
            inputContainerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            inputContainerView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),

            commentTextView.topAnchor.constraint(equalTo: inputContainerView.topAnchor),
            commentTextView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 10),
            commentTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor),
            commentTextView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor),
            commentTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: elementsHeight),

            placeholderLabel.leadingAnchor.constraint(equalTo: commentTextView.leadingAnchor, constant: 5),
            placeholderLabel.centerYAnchor.constraint(equalTo: commentTextView.centerYAnchor),

            postButtonTrailingConstraint,
            postButtonCenterYConstraint,
            sendButton.widthAnchor.constraint(equalToConstant: elementsHeight - 3),
            sendButton.heightAnchor.constraint(equalToConstant: elementsHeight - 3),

            loadingIndicator.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor),
            loadingIndicator.heightAnchor.constraint(equalTo: sendButton.heightAnchor),
            loadingIndicator.widthAnchor.constraint(equalTo: sendButton.widthAnchor),
            loadingIndicator.trailingAnchor.constraint(equalTo: sendButton.trailingAnchor),

            charLimitLabel.bottomAnchor.constraint(equalTo: sendButton.topAnchor),
            charLimitLabel.centerXAnchor.constraint(equalTo: sendButton.centerXAnchor)
        ])
    }

    private func didTapSendButton() {
        guard let text = commentTextView.text, text != placeholder, text != "" else {
            return
        }
        delegate?.sendButtonTapped(commentText: text)
        self.showSendButton()
        self.sendButton.performSuccessfulFeedback()
        self.commentTextView.text.removeAll()
        self.numberOfLines = self.commentTextView.numberOfLines()
        self.handleLinesCount()
        self.handlePlaceholder(for: self.commentTextView)
        self.layoutPostButton()
    }

    private func showLoadingIndicator() {
        loadingIndicator.isHidden = false
        loadingIndicator.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        loadingIndicator.startAnimating()
        UIView.animate(withDuration: 0.3) {
            self.sendButton.alpha = 0
            self.sendButton.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
            self.loadingIndicator.alpha = 1
            self.loadingIndicator.transform = .identity
        } completion: { _ in
            self.sendButton.isHidden = true
        }
    }

    private func showSendButton() {
        self.sendButton.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.sendButton.alpha = 1
            self.sendButton.transform = .identity
            self.loadingIndicator.alpha = 0
            self.loadingIndicator.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        } completion: { _ in
            self.loadingIndicator.isHidden = true
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
        if charactersLeft <= 30 {
            UIView.animate(withDuration: 0.3) {
                self.charLimitLabel.alpha = 1
            }
        } else if charactersLeft > 30 {
            UIView.animate(withDuration: 0.3) {
                self.charLimitLabel.alpha = 0
            }
        }

        guard charactersLeft <= 30 else {
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
                self.sendButton.isEnabled = false
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.sendButton.isEnabled = true
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
                                             attributes: [
                                                .font: commentTextView.font as Any,
                                                .foregroundColor: Colors.label])

        let textPastTheLimit = NSAttributedString(string: String(textView.text.suffix(extraCharactersCount)),
                                                  attributes: [
                                                    .backgroundColor: excessiveTextColor,
                                                    .foregroundColor: Colors.label,
                                                    .font: commentTextView.font as Any])

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
