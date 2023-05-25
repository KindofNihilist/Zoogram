//
//  TableViewFactory.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 24.05.2023.
//

import UIKit.UITableView

protocol TableViewFactory {
    func buildSections() -> [TableViewSectionBuilder]
}
