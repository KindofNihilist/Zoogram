//
//  UIView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 01.11.2023.
//

import UIKit

extension UIView {
    func addSubviews(_ views: UIView...) {
        for view in views {
            addSubview(view)
        }
    }

    func removeSubviews(_ views: UIView...) {
        for view in views {
            view.removeFromSuperview()
        }
    }
}
