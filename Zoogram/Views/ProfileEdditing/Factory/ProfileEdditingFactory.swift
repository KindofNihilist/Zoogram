//
//  ProfileEdditingFactory.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 10.01.2024.
//

import UIKit.UITableView

@MainActor class ProfileEdditingFactory {

    weak var delegate: ProfileEdditingViewDelegate?

    private var tableView: UITableView

    var sections = [TableSectionController]()

    var profilePictureSection: ProfilePictureSection!
    var generalInfoSection: GeneralProfileInfoSection!
    var privateInfoSection: PrivateInfoSection!

    init(tableView: UITableView, profilePictureSection: ProfilePictureSection? = nil, generalInfoSection: GeneralProfileInfoSection? = nil, privateInfoSection: PrivateInfoSection? = nil) {
        self.tableView = tableView
    }

    func buildSections(profilePicture: UIImage, profileInfoModels: [EditProfileFormModel], privateInfoModels: [EditProfileFormModel]) {
        let profilePictureController = ProfilePictureCellController(profilePicture: profilePicture, delegate: self.delegate)
        profilePictureSection = ProfilePictureSection(sectionHolder: tableView, cellControllers: [profilePictureController], sectionIndex: 0)
        sections.append(profilePictureSection)

        var generalInfoControllers = [TableCellController]()

        _ = profileInfoModels.map { model in
            switch model.formKind {
            case .bio:
                generalInfoControllers.append(FormTextViewCellController(model: model, delegate: self.delegate))
            default:
                generalInfoControllers.append(FormTextFieldCellController(model: model, delegate: self.delegate))
            }

        }

        generalInfoSection = GeneralProfileInfoSection(sectionHolder: tableView, cellControllers: generalInfoControllers, sectionIndex: 1)
        sections.append(generalInfoSection)

        var privateInfoControllers = [TableCellController]()

        _ = privateInfoModels.map { model in
            if model.formKind == .gender {
                privateInfoControllers.append(FormGenderPickerCellController(model: model, delegate: self.delegate))
            } else {
                privateInfoControllers.append(FormTextFieldCellController(model: model, delegate: self.delegate))
            }
        }

        privateInfoSection = PrivateInfoSection(sectionHolder: tableView, cellControllers: privateInfoControllers, sectionIndex: 2)
        sections.append(privateInfoSection)
    }

    func updateProfilePicture(with image: UIImage) {
        guard let profilePictureCellController = profilePictureSection.cellController(at: IndexPath(row: 0, section: 0)) as? ProfilePictureCellController else {
            return
        }
        profilePictureCellController.updateProfilePicture(with: image)
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
    }
}
