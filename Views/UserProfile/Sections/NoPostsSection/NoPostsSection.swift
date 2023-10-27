//
//  NoPostsSection.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 26.10.2023.
//

import UIKit

class NoPostsSection: CollectionSectionController {
    override func itemSize() -> CGSize {
        guard let superview = sectionHolder.superview else {
            return CGSize.zero
        }
        return CGSize(width: superview.frame.width, height: superview.frame.width)
    }
}

class NoPostsCellController: GenericCellController<NoPostsCell> {}

class NoPostsCell: UICollectionViewCell {

    let noPostsAlert = PlaceholderView(imageName: "camera", text: "No Posts Yet")

    override init(frame: CGRect) {
        super.init(frame: frame)
        noPostsAlert.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(noPostsAlert)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            noPostsAlert.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            noPostsAlert.heightAnchor.constraint(equalToConstant: 150),
            noPostsAlert.widthAnchor.constraint(equalTo: contentView.widthAnchor)
        ])
    }
}
