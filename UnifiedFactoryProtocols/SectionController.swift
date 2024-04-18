//
//  TableViewSectionBuilder.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 24.05.2023.
//

import UIKit.UITableView

typealias SectionIndex = Int
typealias SupplementaryViewKind = String

class SectionController<T: ReusableCellHolder> {

    var cellControllers: [CellController<T>]
    let sectionHolder: T
    public var sectionIndex: SectionIndex

    init(sectionHolder: T, cellControllers: [CellController<T>], sectionIndex: Int) {
        self.sectionIndex = sectionIndex
        self.sectionHolder = sectionHolder
        self.cellControllers = cellControllers
        self.registerSupplementaryViews()
    }

    public final func numberOfCells() -> Int {
        return cellControllers.count
    }

    public final func cell(at indexPath: IndexPath) -> T.CellType {
        let cellController = cellControllers[indexPath.row]
        cellController.relatedSection = self
        registerCell(at: indexPath)
        let cell = cellController.cellFromReusableCellHolder(sectionHolder, for: indexPath)
        return cell
    }

    public final func cellController(at indexPath: IndexPath) -> CellController<T> {
        let cellController = cellControllers[indexPath.row]
        return cellController
    }

    final func registerCell(at indexPath: IndexPath) {
        let cell = cellControllers[indexPath.row]
        cell.registerCell(in: sectionHolder)
    }

    final func appendCellControllers(controllers: [CellController<T>]) {
        self.cellControllers.append(contentsOf: controllers)
    }

    final func appendCellController(controller: CellController<T>, at position: Int) {
        self.cellControllers.insert(controller, at: position)
    }

    final func removeCellController(at indexPath: IndexPath) {
        self.cellControllers.remove(at: indexPath.row)
    }

    public func registerSupplementaryViews() {}
}

class TableSectionController: SectionController<UITableView> {
    open func canEditCell(at indexPath: IndexPath) -> Bool {
        return false
    }

    open func editingStyleForCell(at indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    public func header() -> UIView? {
        return nil
    }

    public func headerHeight() -> CGFloat {
        return 0
    }

    public func footer() -> UIView? {
        return nil
    }

    public func footerHeight() -> CGFloat {
        return 0
    }

    public func rowHeight() -> CGFloat {
        return 0
    }

    public func estimatedRowHeight() -> CGFloat? {
        return nil
    }

    final func insertCell(with cellController: TableCellController, at position: Int) {
        self.cellControllers.insert(cellController, at: position)
        sectionHolder.beginUpdates()
        let indexPath = IndexPath(row: position, section: sectionIndex)
        sectionHolder.insertRows(at: [indexPath], with: .automatic)
        sectionHolder.endUpdates()
    }

    final func removeCell(at indexPath: IndexPath) {
        self.cellControllers.remove(at: indexPath.row)
        sectionHolder.deleteRows(at: [indexPath], with: .automatic)
    }
}

class CollectionSectionController: SectionController<UICollectionView> {
    
    override init(sectionHolder: UICollectionView, cellControllers: [CellController<UICollectionView>], sectionIndex: Int) {
        super.init(sectionHolder: sectionHolder, cellControllers: cellControllers, sectionIndex: sectionIndex)
    }

    public func itemSize() -> CGSize {
        return CGSize.zero
    }

    public func sectionInsets() -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    public func lineSpacing() -> CGFloat {
        return 0
    }

    public func interitemSpacing() -> CGFloat {
        return 0
    }

    public func header(at indexPath: IndexPath) -> UICollectionReusableView {
        return UICollectionReusableView()
    }

    public func footer(at indexPath: IndexPath) -> UICollectionReusableView {
        return UICollectionReusableView()
    }

    public func headerHeight() -> CGSize? {
        return nil
    }

    public func footerHeight() -> CGSize? {
        return nil
    }
   
    func getSupplementaryView(of kind: SupplementaryViewKind, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            return header(at: indexPath)
        } else if kind == UICollectionView.elementKindSectionFooter {
            return footer(at: indexPath)
        } else {
            return UICollectionReusableView()
        }
    }
    
    func getHeader() -> UICollectionReusableView? {
        let supplementaryView = sectionHolder.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(row: 0, section: sectionIndex))
        return supplementaryView
    }
    
    func getFooter() -> UICollectionReusableView? {
        let supplementaryView = sectionHolder.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: IndexPath(row: 0, section: sectionIndex))
        return supplementaryView
    }

    func calculateSupplementaryViewHeight(for view: UICollectionReusableView) -> CGSize {
        let headerViewSize = CGSize(width: sectionHolder.frame.width, height: UIView.layoutFittingCompressedSize.height)
        return view.systemLayoutSizeFitting(headerViewSize,
                                            withHorizontalFittingPriority: .required,
                                            verticalFittingPriority: .fittingSizeLevel)
    }
}
