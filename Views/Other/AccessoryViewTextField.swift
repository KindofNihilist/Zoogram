//
//  AccessoryViewTextField.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 30.01.2023.
//

import UIKit

class AccessoryViewTextField: UITextField {
    
    let inset: CGFloat = 10
    let buttonInset: CGFloat = 3
    let buttonRightInset: CGFloat = 2
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.insetBy(dx: inset, dy: inset)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds.insetBy(dx: inset , dy: inset)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds.insetBy(dx: inset, dy: inset)
    }
    
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.width - (bounds.height - buttonRightInset),
                      y: bounds.midY - ((bounds.height - buttonInset) / 2),
                      width: bounds.height - buttonInset,
                      height: bounds.height - buttonInset)
    }
}
