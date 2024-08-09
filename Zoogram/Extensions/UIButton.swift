//
//  UIButton.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 26.06.2024.
//

import UIKit.UIButton

extension UIButton {
    func setImage(withSystemName imageName: String, pointSize: CGFloat = 23, weight: UIImage.SymbolWeight = .medium) {
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        let image = UIImage(systemName: imageName, withConfiguration: imageConfiguration)
        self.setImage(image, for: .normal)
    }
}
