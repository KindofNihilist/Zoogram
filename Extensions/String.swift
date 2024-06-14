//
//  String.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 22.12.2023.
//

import Foundation
import UIKit.NSParagraphStyle

extension String {
    func trimmingExtraWhitespace() -> String {
        return self.replacingOccurrences(of: "(?<=\\s)\\s+|\\s+(?=$)|(?<=^)\\s+",
                                         with: "",
                                         options: .regularExpression)
    }

    func safeDatabaseKey() -> String {
        return self.replacingOccurrences(of: ".", with: "-")
    }

    func lineWithSpacing(_ spacing: CGFloat) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = spacing
        let attributedString = NSAttributedString(string: self, attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        return attributedString
    }
}
