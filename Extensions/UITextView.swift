//
//  UITextView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 01.11.2023.
//

import UIKit.UITextView

extension UITextView {

//    func numberOfLines() -> Int {
//        return Int(self.contentSize.height / self.font!.lineHeight)
//    }

    func sizeFit(width: CGFloat) -> CGSize {
        let fixedWidth = width
        let newSize = sizeThatFits(CGSize(width: fixedWidth, height: .greatestFiniteMagnitude))
        return CGSize(width: fixedWidth, height: newSize.height)
    }

    func numberOfLines() -> Int {
        let size = self.sizeFit(width: self.bounds.width)
        let numLines = Int(size.height / (self.font?.lineHeight ?? 1.0))
        return numLines
    }
}
