//
//  TabItemView.swift
//  Countries
//
//  Created by Artem Dolbiiev on 21.09.2023.
//

import UIKit

class TabItemView: UIView {

    private let tabItem: TabItem
    private let selectedColor = Colors.label
    private let deselectedColor = UIColor.systemGray

    let itemIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.tintColor = .label
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    init(tabItem: TabItem) {
        self.tabItem = tabItem
        super.init(frame: CGRect.zero)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSelected() {
        itemIconView.image = tabItem.selectedIcon.withRenderingMode(.automatic)
        itemIconView.tintColor = selectedColor
    }

    func setDeselected() {
        itemIconView.image = tabItem.icon.withRenderingMode(.automatic)
        itemIconView.tintColor = deselectedColor
    }

    private func setupViews() {
        self.addSubview(itemIconView)
        itemIconView.image = tabItem.icon.withRenderingMode(.automatic)
        itemIconView.tintColor = deselectedColor
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            itemIconView.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            itemIconView.heightAnchor.constraint(equalToConstant: 30),
            itemIconView.widthAnchor.constraint(equalToConstant: 30),
            itemIconView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
        ])
    }
}
