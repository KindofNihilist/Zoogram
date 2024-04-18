//
//  FormTextViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 12.01.2024.
//

import UIKit.UITableViewCell

protocol TableViewTextViewDelegate: AnyObject {
    func didUpdateTextView()
}

class FormTextViewCell: FormEdditingViewCell {

    weak var textViewDelegate : TableViewTextViewDelegate?

    private var placeholderText: String?

    let textView: VerticallyCenteredTextView = {
        let textView = VerticallyCenteredTextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = Colors.detailGray
        textView.font = CustomFonts.regularFont(ofSize: 14)
        textView.layer.cornerCurve = .continuous
        textView.layer.cornerRadius = 12
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        return textView
    }()

    override func configureRightView() {
        rightView.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: rightView.topAnchor),
            textView.leadingAnchor.constraint(equalTo: rightView.leadingAnchor),
            textView.bottomAnchor.constraint(equalTo: rightView.bottomAnchor),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 27),
            textView.trailingAnchor.constraint(equalTo: rightView.trailingAnchor)
        ])
    }

    override func configure(with model: EditProfileFormModel) {
        super.configure(with: model)
        textView.delegate = self
        textView.text = model.value
        placeholderText = model.placeholder
        setupPlaceholder()
    }

    private func setupPlaceholder() {
        if textView.text.trimmingExtraWhitespace().isEmpty {
            textView.text = self.placeholderText
            textView.textColor = .placeholderText
        }
    }
}

extension FormTextViewCell: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = nil
            textView.textColor = Colors.label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        setupPlaceholder()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        return numberOfChars < 130
    }

    func textViewDidChange(_ textView: UITextView) {
        if var model = self.model {
            model.value = textView.text
            delegate?.didUpdateModel(model)
        }
        textViewDelegate?.didUpdateTextView()
    }
}
