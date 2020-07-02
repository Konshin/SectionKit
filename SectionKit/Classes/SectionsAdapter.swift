//
//  SectionsAdapter.swift
//  SocialTrading
//
//  Created by akonshin on 07/01/2019.
//  Copyright © 2019 com.exness. All rights reserved.
//

import UIKit
import UICollectionUpdates

// swiftlint:disable file_length

/// Адаптер для работы с секциями
public final class SectionsAdapter: NSObject {

    // MARK: - Nested types

    /// Тип для идентификатора ячейки
    private typealias CellId = String

    public typealias Completion = (Bool) -> Void

    private enum State {
        case idle
        case updating(pending: ReloadParameters?, completions: [Completion])
    }

    // MARK: - properties

    /// Источник данных по секциям
    public weak var dataSource: SectionsAdapterDataSource?
    /// Делегация над скроллом UICollectionView
    public weak var scrollDelegate: UIScrollViewDelegate?

    /// Коллекшен вью
    private weak var collectionView: UICollectionView?
    /// Коллекшен вью
    private(set) weak public var viewController: UIViewController?

    // MARK: - private properties

    /// Список секций
    private var sections: [SectionPresentable] = []
    /// Связь секций и индекса в списке
    private var sectionsMap: [SectionPresentable.Identifier: Int] = [:]

    /// Зарегистрированные типы ячеек
    private var registeredCellClasses: Set<CellId> = []
    /// Зарегистрированные Хедеры
    private var registeredHeaderClasses: Set<CellId> = []
    /// Зарегистрированные Футеры
    private var registeredFooterClasses: Set<CellId> = []
    /// Ячейки для арсчета размера
    private var calculationCells: [CellId: UICollectionViewCell] = [:]
    /// Ячейки для арсчета размера
    private var calculationSupplementaryViews: [CellId: UICollectionReusableView] = [:]

    private var updateState: State = .idle

    // MARK: - constructors

    public init(collectionView: UICollectionView, viewController: UIViewController) {
        self.collectionView = collectionView
        self.viewController = viewController
        super.init()

        collectionView.delegate = self
        collectionView.dataSource = self
    }

    // MARK: - getters

    public func startPoint(for section: SectionPresentable) -> CGPoint? {
        guard let sectionIndex = sectionsMap[section.id], let collectionView = collectionView else {
            return nil
        }
        let ip = IndexPath(item: 0, section: sectionIndex)
        guard let rect = collectionView.layoutAttributesForSupplementaryElement(ofKind: SectionSupplementaryKind.header.value, at: ip)?.frame else {
            return nil
        }
        return rect.origin
    }

    // MARK: - functions

    public func updateViewController(_ controller: UIViewController?) {
        viewController = controller
    }

    // MARK: - private functions

    private func dequeueIdentifier(for aClass: UICollectionReusableView.Type) -> CellId {
        return className(aClass)
    }

    private func isCellRegistered(_ cellClass: UICollectionReusableView.Type) -> Bool {
        let id = dequeueIdentifier(for: cellClass)
        return registeredCellClasses.contains(id)
    }

    private func isHeaderRegistered(_ cellClass: UICollectionReusableView.Type) -> Bool {
        let id = dequeueIdentifier(for: cellClass)
        return registeredHeaderClasses.contains(id)
    }

    private func isFooterRegistered(_ cellClass: UICollectionReusableView.Type) -> Bool {
        let id = dequeueIdentifier(for: cellClass)
        return registeredFooterClasses.contains(id)
    }

    private func calculationCell(for cellType: SectionReusableViewType<UICollectionViewCell>, collectionView: UICollectionView) -> UICollectionViewCell {
        let id = dequeueIdentifier(for: cellType.viewClass)
        if let current = calculationCells[id] {
            return current
        } else {
            let cell: UICollectionViewCell
            switch cellType {
            case .code(let cellClass):
                cell = cellClass.init(frame: CGRect(x: 0, y: 0, width: collectionView.bounds.width, height: 100))
            case .nib(let cellClass):
                let nibName = className(cellClass)
                cell = (Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)?.first as? UICollectionViewCell) ?? cellClass.init()
            }
            calculationCells[id] = cell
            return cell
        }
    }

    private func calculationSupplementaryView(for viewType: SectionReusableViewType<UICollectionReusableView>,
                                              collectionView: UICollectionView) -> UICollectionReusableView {
        let id = dequeueIdentifier(for: viewType.viewClass)
        if let current = calculationSupplementaryViews[id] {
            return current
        } else {
            let cell: UICollectionReusableView
            switch viewType {
            case .code(let cellClass):
                cell = cellClass.init(frame: CGRect(x: 0, y: 0, width: collectionView.bounds.width, height: 100))
            case .nib(let cellClass):
                let nibName = className(cellClass)
                cell = (Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)?.first as? UICollectionReusableView) ?? cellClass.init()
            }
            calculationSupplementaryViews[id] = cell
            return cell
        }
    }

    /// Зарегистрировать класс в качестве хедера, если необходимо
    private func registerSupplementaryIfNeeded(type: SectionReusableViewType<UICollectionReusableView>,
                                               kind: SectionSupplementaryKind) {
        let aClass = type.viewClass
        let id = dequeueIdentifier(for: aClass)
        let isRegistered: Bool
        switch kind {
        case .header:
            isRegistered = isHeaderRegistered(aClass)
        case .footer:
            isRegistered = isFooterRegistered(aClass)
        }
        if !isRegistered {
            switch type {
            case .code:
                collectionView?.register(aClass,
                                         forSupplementaryViewOfKind: kind.value,
                                         withReuseIdentifier: id)
            case .nib:
                let nib = UINib(nibName: id, bundle: nil)
                collectionView?.register(nib,
                                         forSupplementaryViewOfKind: kind.value,
                                         withReuseIdentifier: id)
            }
        }
    }

}

// MARK: - UICollectionViewDataSource
extension SectionsAdapter: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard sections.count > section else { return 0 }
        return sections[section].numberOfElements()
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionIndex = indexPath.section
        let itemIndex = indexPath.item
        let section = sections[sectionIndex]
        let type = section.cellType(at: itemIndex)

        let cellClass: UICollectionViewCell.Type = type.viewClass
        let reuseId = dequeueIdentifier(for: cellClass)
        
        let registerAction: (UICollectionViewCell.Type) -> Void
        switch type {
        case .code:
            registerAction = { cellClass in
                collectionView.register(cellClass,
                                        forCellWithReuseIdentifier: reuseId)
            }
        case .nib:
            registerAction = { cellClass in
                let cellClassName = className(cellClass)
                collectionView.register(UINib(nibName: cellClassName, bundle: nil),
                                        forCellWithReuseIdentifier: reuseId)
            }
        }

        if !isCellRegistered(cellClass) {
            registerAction(cellClass)
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseId, for: indexPath)
        section.configure(cell: cell, at: itemIndex)
        return cell
    }

    // MARK: supplementary
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let section = sections[indexPath.section]
        
        guard let kindType = SectionSupplementaryKind(string: kind) else {
            return UICollectionReusableView()
        }
        let type = section.supplementaryType(for: kindType) ?? .code(UICollectionReusableView.self)
        
        registerSupplementaryIfNeeded(type: type, kind: kindType)
        let id = dequeueIdentifier(for: type.viewClass)
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                   withReuseIdentifier: id,
                                                                   for: indexPath)
        section.configure(supplementaryView: view,
                          kind: kindType,
                          at: indexPath.item)
        return view
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        guard let kindType = SectionSupplementaryKind(string: elementKind) else { return }
        let section = sections[indexPath.section]
        section.willDisplaySupplementary(supplementaryView: view,
                                         kind: kindType,
                                         at: indexPath.item)
    }

}

// MARK: - UICollectionViewDelegate
extension SectionsAdapter: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        section.select(at: indexPath.item)
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        section.willDisplayCell(at: indexPath.item)
    }

}

// MARK: - UICollectionViewFlowLayout
extension SectionsAdapter: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let section = sections[section]
        return section.insets
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let section = sections[section]
        return section.minimumLineSpacing
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let section = sections[section]
        return section.minimumInterItemSpacing
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let section = sections[indexPath.section]
        let index = indexPath.item
        let insets = section.insets
        let contentWidth = collectionView.bounds.width - insets.left - insets.right

        let sizeCalculation = section.sizeForCell(at: index, contentWidth: contentWidth)
        switch sizeCalculation {
        case .specific(let size):
            return size
        case .automatic:
            let calculationCell = self.calculationCell(for: section.cellType(at: index), collectionView: collectionView)
            calculationCell.prepareForReuse()
            section.configure(cell: calculationCell, at: index)
            calculationCell.updateConstraints()

            let size = calculationCell.contentView.systemLayoutSizeFitting(CGSize(width: contentWidth,
                                                                                  height: UIView.layoutFittingCompressedSize.height),
                                                                           withHorizontalFittingPriority: .required,
                                                                           verticalFittingPriority: .fittingSizeLevel)

            return CGSize(width: contentWidth, height: size.height.rounded(.up))
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return sizeForSupplementary(.header,
                                    collectionView: collectionView,
                                    section: section)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return sizeForSupplementary(.footer,
                                    collectionView: collectionView,
                                    section: section)
    }

    private func sizeForSupplementary(_ kind: SectionSupplementaryKind,
                                      collectionView: UICollectionView,
                                      section: Int) -> CGSize {
        let section = sections[section]
        guard let viewType = section.supplementaryType(for: kind) else {
            return .zero
        }
        let insets = section.insets
        let contentWidth = collectionView.bounds.width - insets.left - insets.right
        let sizeCalculation = section.sizeForSupplementary(of: kind, contentWidth: contentWidth)
        switch sizeCalculation {
        case .specific(let size):
            return size
        case .automatic:
            let calculationView = self.calculationSupplementaryView(for: viewType,
                                                                    collectionView: collectionView)
            calculationView.prepareForReuse()
            section.configure(supplementaryView: calculationView, kind: kind, at: 0)
            calculationView.updateConstraintsIfNeeded()

            let size = calculationView.systemLayoutSizeFitting(CGSize(width: contentWidth,
                                                                      height: UIView.layoutFittingCompressedSize.height),
                                                               withHorizontalFittingPriority: .required,
                                                               verticalFittingPriority: .fittingSizeLevel)

            return CGSize(width: contentWidth, height: size.height.rounded(.up))
        }
    }

}

// MARK: - UIScrollViewDelegate
extension SectionsAdapter: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollDelegate?.scrollViewDidScroll?(scrollView)
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }

}

// MARK: - Reload logic
extension SectionsAdapter {

    public func reloadData(animated: Bool, completion: Completion? = nil) {
        guard let dataSource = dataSource else {
            return
        }

        let newSections = dataSource.sections()
        var updates: ReloadParameters
        if animated, #available(iOS 13, *) {
            let oldSections = self.sections
            let diff = newSections.difference(from: oldSections) { (l, r) -> Bool in
                return l.id == r.id
            }
            
            let batchUpdates = UICollectionUpdates(diff: diff)
            updates = ReloadParameters(updates: batchUpdates)
        } else {
            updates = ReloadParameters(fullReload: true)
        }
        updates.setNewSections(newSections)

        addUpdate(updates, completions: completion.flatMap { [$0] } ?? [])
    }

    public func performUpdates(_ updates: UICollectionSectionUpdates, section: SectionPresentable, completion: Completion?) {
        guard let sectionIndex = sectionsMap[section.id] else {
            return
        }

        var batchUpdates = UICollectionUpdates()
        batchUpdates = batchUpdates.update(with: updates, section: sectionIndex)
        let reloadParams = ReloadParameters(updates: batchUpdates, fullReload: false)
        addUpdate(reloadParams, completions: completion.map { [$0] } ?? [])
    }

    public func reload(section: SectionPresentable, animated: Bool, completion: Completion? =  nil) {
        guard let sectionIndex = sectionsMap[section.id] else {
            return
        }
        let reloadParams: ReloadParameters
        if animated {
            let update = UICollectionUpdates(reloadSections: [sectionIndex])
            reloadParams = ReloadParameters(updates: update, fullReload: false)
        } else {
            reloadParams = ReloadParameters(fullReload: true)
        }
        addUpdate(reloadParams, completions: completion.flatMap { [$0] } ?? [])
    }

    public func endRefreshing() {
        guard let collectionView = collectionView else { return }

        let action: Completion = { _ in
            if #available(iOS 10.0, *) {
                DispatchQueue.main.async {
                    collectionView.refreshControl?.endRefreshing()
                }
            }
            
        }

        switch updateState {
        case .idle:
            action(true)
        case .updating(let pending, var completions):
            completions.append(action)
            self.updateState = .updating(pending: pending, completions: completions)
        }
    }
    
    // MARK: private

    private func addUpdate(_ update: ReloadParameters, completions: [Completion]) {
        DispatchQueue.main.async {
            var paramsToUpdate: ReloadParameters?
            switch self.updateState {
            case .idle:
                paramsToUpdate = update
            case .updating(let pending, var pendingCompletions):
                pendingCompletions += completions
                self.updateState = .updating(pending: pending?.merge(with: update) ?? update, completions: pendingCompletions)
            }

            if let parameters = paramsToUpdate {
                self.updateState = .updating(pending: nil, completions: completions)

                if let sections = parameters.newSections {
                    self.sections.forEach { $0.sectionsContext = nil }
                    self.sectionsMap.removeAll()
                    self.sections = sections
                    self.sections.enumerated().forEach { (index, section) in
                        self.sectionsMap[section.id] = index
                        section.sectionsContext = self
                    }
                }

                let completion: (Bool) -> Void = { [weak self] finished in
                    guard let self = self else { return }

                    let previousState = self.updateState
                    self.updateState = .idle
                    if case .updating(let pending, let completions) = previousState {
                        if let updates = pending {
                            self.addUpdate(updates, completions: completions)
                            return
                        } else {
                            completions.forEach {
                                $0(finished)
                            }
                        }
                    }
                }

                // Dont use animations when we are not in the window hierarchy
                if parameters.fullReload || self.collectionView?.window == nil {
                    CATransaction.begin()
                    CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
                    self.collectionView?.reloadData()
                    self.collectionView?.collectionViewLayout.invalidateLayout()
                    self.collectionView?.layoutIfNeeded()
                    CATransaction.commit()

                    completion(true)
                } else {
                    self.collectionView?.performOrReload(updates: parameters.updates, with: Void(), completion: completion)
                }
            }
        }
    }

}

// MARK: - SectionsDisplayable
extension SectionsAdapter: SectionsGroupDisplayable {

    public var scrollView: UIScrollView? {
        return collectionView
    }

    public func cellForItem(at index: Int, section: SectionPresentable) -> UICollectionViewCell? {
        guard let sectionIndex = sectionsMap[section.id] else {
            return nil
        }
        let indexPath = IndexPath(item: index, section: sectionIndex)
        return collectionView?.cellForItem(at: indexPath)
    }

    public func indexForCell(_ cell: UICollectionViewCell, section: SectionPresentable) -> Int? {
        return collectionView?.indexPath(for: cell)?.item
    }

    public func updateLayout(section: SectionPresentable, at indexes: [Int]?) {
        guard let sectionIndex = sectionsMap[section.id] else {
            return
        }

        if let indexes = indexes {
            collectionView?.performBatchUpdates({
                let context = UICollectionViewFlowLayoutInvalidationContext()
                context.invalidateItems(at: indexes.map { IndexPath(item: $0, section: sectionIndex) })
                self.collectionView?.collectionViewLayout.invalidateLayout(with: context)
            },
                                                completion: nil)
        } else {
            collectionView?.collectionViewLayout.invalidateLayout()
        }
    }

    public func scrollToItem(_ section: SectionPresentable, index: Int, at position: UICollectionView.ScrollPosition, animated: Bool) {
        guard let sectionIndex = sectionsMap[section.id], let collectionView = collectionView else {
            return
        }
        let ip = IndexPath(item: index, section: sectionIndex)
        collectionView.scrollToItem(at: ip, at: position, animated: animated)
    }

    public func scrollToSupplementary(_ section: SectionPresentable,
                               kind: SectionSupplementaryKind,
                               index: Int,
                               at position: UICollectionView.ScrollPosition,
                               animated: Bool) {
        guard let sectionIndex = sectionsMap[section.id], let collectionView = collectionView else {
            return
        }
        let ip = IndexPath(item: index, section: sectionIndex)
        guard let rect = collectionView.layoutAttributesForSupplementaryElement(ofKind: kind.value, at: ip)?.frame else {
            return
        }

        var boundsHeight: CGFloat = collectionView.bounds.height
        if #available(iOS 11.0, *) {
            boundsHeight -= collectionView.adjustedContentInset.top + collectionView.adjustedContentInset.bottom
        } else {
            boundsHeight -= collectionView.contentInset.top + collectionView.contentInset.bottom
        }
        
        var rectToScroll = rect
        switch position {
        case .bottom:
            rectToScroll.origin.y = rectToScroll.minY - boundsHeight + rectToScroll.height
            rectToScroll.size.height = boundsHeight
        case .top:
            rectToScroll.size.height = boundsHeight
        case .centeredVertically:
            let offset = max((boundsHeight - rectToScroll.height) / 2, 0)
            rectToScroll.origin.y = rectToScroll.minY - offset
            rectToScroll.size.height = boundsHeight
        default:
            break
        }

        collectionView.scrollRectToVisible(rectToScroll, animated: animated)
    }

    public func performUpdates(_ updates: UICollectionUpdates, since firstSection: SectionPresentable) {
        guard !updates.isEmpty, let sectionIndex = sectionsMap[firstSection.id], let dataSource = dataSource else {
            return
        }

        let updates = updates.shiftIndexes(sectionsShift: sectionIndex)
        let reloadParams = ReloadParameters(updates: updates, fullReload: false, newSections: dataSource.sections())
        addUpdate(reloadParams, completions: [])
    }

    public func rectForCell(at index: Int, section: SectionPresentable) -> CGRect? {
        guard let sectionIndex = sectionsMap[section.id], let collectionView = collectionView, let attributes = collectionView.layoutAttributesForItem(at: IndexPath(item: index, section: sectionIndex)) else {
            return nil
        }

        return attributes.frame
    }

    public func rectForSupplementary(kind: SectionSupplementaryKind, index: Int, section: SectionPresentable) -> CGRect? {
        guard let sectionIndex = sectionsMap[section.id], let collectionView = collectionView else {
            return nil
        }
        let ip = IndexPath(item: index, section: sectionIndex)
        return collectionView.layoutAttributesForSupplementaryElement(ofKind: kind.value, at: ip)?.frame
    }

}

private struct ReloadParameters {

    private(set) var updates: UICollectionUpdates = UICollectionUpdates()

    private(set) var fullReload: Bool = false

    private(set) var newSections: [SectionPresentable]?

    mutating func addUpdates(_ updates: UICollectionUpdates) {
        guard !fullReload else { return }

        self.updates = self.updates.merge(with: updates)
    }

    mutating func setFullReload() {
        updates = UICollectionUpdates()
        fullReload = true
    }

    mutating func setNewSections(_ sections: [SectionPresentable]?) {
        newSections = sections
    }

    func merge(with params: ReloadParameters) -> ReloadParameters {
        let newSections = params.newSections ?? self.newSections
        if fullReload || params.fullReload {
            return ReloadParameters(updates: UICollectionUpdates(), fullReload: true, newSections: newSections)
        }

        return ReloadParameters(updates: updates.merge(with: params.updates),
                                fullReload: false,
                                newSections: newSections)
    }

}

// MARK: - extra utilities
extension SectionsAdapter {

    public func generateCell(for section: SectionPresentable, index: Int) -> UICollectionViewCell? {
        guard section.numberOfElements() > index else { return nil }

        let cellType = section.cellType(at: index)
        let cell = cellType.viewClass.init()
        section.configure(cell: cell, at: index)
        return cell
    }

}
