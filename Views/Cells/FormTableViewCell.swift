//
//  FormTableViewCell.swift
//  Zoogram
//
//  Created by Artem Dolbiev on 19.01.2022.
//

import UIKit

protocol FormTableViewCellDelegate: AnyObject {
    func formTableViewCell(_ cell: FormTableViewCell, didUpdateModel model: EditProfileFormModel)
}

class FormTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    static let identifier = "FormTableViewCell"
    
    private var model: EditProfileFormModel?
    
    public weak var delegate: FormTableViewCellDelegate?
    
    private let formLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.systemFont(ofSize: 15)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let textField: UITextField = {
        let textField = UITextField()
        textField.returnKeyType = .done
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let divider: UIView = {
        let divider = UIView()
        divider.backgroundColor = .lightGray
        divider.translatesAutoresizingMaskIntoConstraints = false
        return divider
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubviews(formLabel, textField, divider)
        setupConstraints()
        textField.delegate = self
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(with model: EditProfileFormModel) {
        self.model = model
        formLabel.text = model.label
        textField.placeholder = model.placeholder
        textField.text = model.value
    }
    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        formLabel.text = nil
//        textField.placeholder = nil
//        textField.text = nil
//    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            formLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            formLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            formLabel.widthAnchor.constraint(equalToConstant: self.frame.width/4),
            formLabel.heightAnchor.constraint(equalTo: self.heightAnchor),
            
            textField.leadingAnchor.constraint(equalTo: formLabel.trailingAnchor, constant: 20),
            textField.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            textField.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -1),
            
            divider.leadingAnchor.constraint(equalTo: textField.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: textField.trailingAnchor),
            divider.topAnchor.constraint(equalTo: textField.bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),
            
        ])
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        model?.value = textField.text
        guard let model = model else {
            return
        }
        delegate?.formTableViewCell(self, didUpdateModel: model )
    }
    
}
