//
//  CustomTextField.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 26.12.2023.
//

import UIKit.UITextField

class CustomTextField: UITextField {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.leftViewMode = .always
        self.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        self.autocapitalizationType = .none
        self.autocorrectionType = .no
        self.font = CustomFonts.regularFont(ofSize: 17)
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 13
        self.layer.cornerCurve = .continuous
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
