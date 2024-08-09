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
        guard let textContainerHeight = textLayoutManager?.textContainer?.size.height else {
            return
        }
        let topInset = (bounds.size.height - textContainerHeight) / 2
        textContainerInset.top = max(0, topInset)
    }
}
