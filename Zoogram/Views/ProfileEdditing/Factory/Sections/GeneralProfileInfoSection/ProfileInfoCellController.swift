//
//  GeneralProfileInfoCell.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 10.01.2024.
//

import UIKit.UITableViewCell

class ProfileInfoCellController<T: FormEdditingViewCell>: GenericCellController<T> {

    weak var delegate: ProfileEdditingCellDelegate?
    var model: EditProfileFormModel
    var shouldHideDivider: Bool = false

    init(model: EditProfileFormModel, delegate: ProfileEdditingCellDelegate?) {
        self.delegate = delegate
        self.model = model
    }

    override func configureCell(_ cell: T, at indexPath: IndexPath? = nil) {
        cell.configure(with: self.model)
        cell.backgroundColor = Colors.naturalBackground
        cell.delegate = self.delegate
    }
}

class FormGenderPickerCellController: ProfileInfoCellController<FormGenderPickerCell> {}
class FormTextFieldCellController: ProfileInfoCellController<FormTextFieldCell> {}
class FormTextViewCellController: ProfileInfoCellController<FormTextViewCell> {

    override func configureCell(_ cell: FormTextViewCell, at indexPath: IndexPath? = nil) {
        super.configureCell(cell)
        cell.isDividerHidden = true
        if let delegate = self.delegate as? TableViewTextViewDelegate {
            cell.textViewDelegate = delegate
        }
    }
}
