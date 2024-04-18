//
//  NSLayoutConstraint.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 16.11.2023.
//

import UIKit.NSLayoutConstraint

extension NSLayoutConstraint {
    func deactivate() {
        self.isActive = false
    }
}
