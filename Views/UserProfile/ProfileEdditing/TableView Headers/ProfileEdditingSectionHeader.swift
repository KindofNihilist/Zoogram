//
//  EditProfileSectionHeader.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 20.01.2022.
//

import UIKit

class ProfileEdditingSectionHeader: UITableViewHeaderFooterView {
    static let identifier = "EditProfileSectionHeader"

    let title = UILabel()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        configureContents()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        
    }
    
    func configureContents() {
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = CustomFonts.boldFont(ofSize: 19)
        title.textColor = .label
        contentView.addSubview(title)
        
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor, constant: -5),
            title.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            title.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: -5 ),
            title.heightAnchor.constraint(equalToConstant: 30),
        ])
    }
    
}
