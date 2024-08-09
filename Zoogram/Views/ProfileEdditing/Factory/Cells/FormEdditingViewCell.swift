//
//  FormTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 19.01.2022.
//

import UIKit

@MainActor protocol ProfileEdditingCellDelegate: AnyObject {
    func didUpdateModel(_ model: EditProfileFormModel)
}

class FormEdditingViewCell: UITableViewCell {

    var model: EditProfileFormModel?

    weak var delegate: ProfileEdditingCellDelegate?

    var isDividerHidden: Bool = false {
        didSet {
            self.divider.isHidden = isDividerHidden
        }
    }

    let formLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = CustomFonts.boldFont(ofSize: 15)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()

    var rightView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let divider: UIView = {
        let divider = UIView()
        divider.backgroundColor = Colors.detailGray
        divider.layer.cornerCurve = .continuous
        divider.layer.cornerRadius = 1
        divider.translatesAutoresizingMaskIntoConstraints = false
        return divider
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubviews(formLabel, rightView, divider)
        setupConstraints()
        clipsToBounds = true
        backgroundColor = Colors.detailGray
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with model: EditProfileFormModel) {
        self.model = model
        formLabel.text = model.label
    }

    func configureRightView() {}

    func setupConstraints() {
        NSLayoutConstraint.activate([
            formLabel.topAnchor.constraint(greaterThanOrEqualTo: rightView.topAnchor),
            formLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),
            formLabel.centerYAnchor.constraint(equalTo: rightView.centerYAnchor),
            formLabel.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor),

            rightView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            rightView.leadingAnchor.constraint(greaterThanOrEqualTo: formLabel.trailingAnchor),
            rightView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15),
            rightView.heightAnchor.constraint(greaterThanOrEqualToConstant: 30),
            rightView.widthAnchor.constraint(equalToConstant: self.frame.width / 1.45),

            divider.topAnchor.constraint(equalTo: rightView.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: rightView.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: rightView.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 2),
            divider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)

        ])
        configureRightView()
    }
}
