//
//  AccessoryViewTextField.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 30.01.2023.
//

import UIKit

class AccessoryViewTextView: UITextView {

    var placeholder = "" {
        didSet {
            self.text = placeholder
        }
    }

    var isEditing: Bool = false

    var rightView: UIView? {
        didSet {
            setupRightView()
        }
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.textColor = .placeholderText
        self.clipsToBounds = true
        self.contentInset = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 30)
        self.isScrollEnabled = false
        self.contentSize = sizeThatFits(self.frame.size)
    }

    func setupRightView() {
        guard let rightView = rightView else {
            return
        }
        rightView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightView)
        NSLayoutConstraint.activate([
            rightView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -5),
            rightView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: 5),
            rightView.heightAnchor.constraint(equalToConstant: 30),
            rightView.widthAnchor.constraint(equalToConstant: 30)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AccessoryViewTextField: UITextField {

    let inset: CGFloat = 10
    let buttonInset: CGFloat = 3
    let buttonRightInset: CGFloat = 2
    var insets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 5)

    private func setInsets(forBounds bounds: CGRect) -> CGRect {
        var totalInsets = insets
        if let leftView = leftView { totalInsets.left += leftView.frame.origin.x }
        if let rightView = rightView { totalInsets.right += rightView.bounds.size.width + 5}
        return bounds.inset(by: totalInsets)
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return setInsets(forBounds: bounds)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return setInsets(forBounds: bounds)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return setInsets(forBounds: bounds)
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.rightViewRect(forBounds: bounds)
        rect.origin.x -= insets.right
        let customRect = CGRect(
            x: rect.minX - 2.5,
            y: rect.minY - 2.5,
            width: bounds.height - 5,
            height: bounds.height - 5)
        return customRect
    }

    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.leftViewRect(forBounds: bounds)
        rect.origin.x += insets.left
        return rect
    }
}
