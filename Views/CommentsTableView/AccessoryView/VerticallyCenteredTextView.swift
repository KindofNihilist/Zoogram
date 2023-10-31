//
//  VerticallyCenteredTextView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 31.10.2023.
//

import UIKit

class VerticallyCenteredTextView: UITextView {

    override func layoutSubviews() {
        super.layoutSubviews()

        let rect = layoutManager.usedRect(for: textContainer)
        let topInset = (bounds.size.height - rect.height) / 2
        textContainerInset.top = max(0, topInset)
    }
}
