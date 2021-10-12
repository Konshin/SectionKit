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

    /// The reload completion type
    public typealias Completion = (Bool) -> Void
    
    /// The cell identifier
    private typealias CellId = String
    /// Current reloading state
    private enum State {
        case idle
        case updating(Completion? = nil)
    }

    // MARK: - properties

    /// The data provider for SectionsAdapter
    public weak var dataSource: SectionsAdapterDataSource?
    /// The methods declared by the UIScrollViewDelegate protocol allow the adopting delegate to respond to messages from the UICollectionView class and thus respond to, and in some affect, operations such as scrolling, zooming, deceleration of scrolled content, and scrolling animations.
    public weak var scrollDelegate: UIScrollViewDelegate?

    /// The collection view
    private weak var collectionView: UICollectionView?
    /// Коллекшен вью
    private(set) weak public var viewController: UIViewController?
    
    private var state: State = .idle

    // MARK: - private properties

    /// The data for dispalying
    private(set) var data: SectionsData = SectionsData(groups: [])

    /// The registered cell types
    private var registeredCellClasses: Set<CellId> = []
    /// The registered header types
    private var registeredHeaderClasses: Set<CellId> = []
    /// The registered footer types
    private var registeredFooterClasses: Set<CellId> = []
    /// The cached cells for the calculation logic
    private var calculationCells: [CellId: UICollectionViewCell] = [:]
    /// The cached supplementary views for the calculation logic
    private var calculationSupplementaryViews: [CellId: UICollectionReusableView] = [:]

    // MARK: - constructors

    public init(collectionView: UICollectionView?, viewController: UIViewController) {
        self.viewController = viewController
        super.init()
        
        if let collectionView = collectionView {
            updateCollectionView(collectionView)
        }
    }

    // MARK: - getters

    public func startPoint(for section: SectionPresentable) -> CGPoint? {
        guard let sectionIndex = data.sectionsMap[section.id], let collectionView = collectionView else {
            return nil
        }
        let ip = IndexPath(item: 0, section: sectionIndex)
        guard let rect = collectionView.layoutAttributesForSupplementaryElement(ofKind: SectionSupplementaryKind.header.value, at: ip)?.frame else {
            return nil
        }
        return rect.origin
    }
    
    func section(at index: Int) -> SectionPresentable {
        return data.sections[index]
    }
    
    @available(iOS 13, *)
    func collectionUpdates(
        oldSections: [SectionPresentable],
        newSections: [SectionPresentable],
        ignoreSectionReloads: [SectionPresentable.Identifier]
    ) -> UICollectionUpdates {
        let diff = newSections.difference(from: oldSections) { (l, r) -> Bool in
            return l.id == r.id
        }
        
        let batchUpdates = UICollectionUpdates(diff: diff)
        var reloadIndices = Array(0..<oldSections.count)
        if !ignoreSectionReloads.isEmpty {
            let ignoreIds = Set(ignoreSectionReloads)
            reloadIndices = reloadIndices.filter { sectionIndex in
                !ignoreIds.contains(oldSections[sectionIndex].id)
            }
        }
        let reloads = UICollectionUpdates(
            reloadSections: IndexSet(reloadIndices)
        )
        return batchUpdates.merge(with: reloads)
    }

    // MARK: - functions

    public func updateViewController(_ controller: UIViewController?) {
        viewController = controller
    }
    
    public func updateCollectionView(_ collectionView: UICollectionView) {
        if let previous = self.collectionView {
            if previous.dataSource === self {
                previous.dataSource = nil
            }
            if previous.delegate === self {
                previous.delegate = nil
            }
        }
        
        self.collectionView = collectionView
        collectionView.delegate = self
        collectionView.dataSource = self
    }

    // MARK: - private functions

    private func dequeueIdentifier(for aClass: UICollectionReusableView.Type) -> CellId {
        return className(aClass)
    }

    private func isCellRegistered(_ id: CellId) -> Bool {
        return registeredCellClasses.contains(id)
    }

    private func isHeaderRegistered(_ id: CellId) -> Bool {
        return registeredHeaderClasses.contains(id)
    }

    private func isFooterRegistered(_ id: CellId) -> Bool {
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
            isRegistered = isHeaderRegistered(id)
        case .footer:
            isRegistered = isFooterRegistered(id)
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
            
            switch kind {
            case .header:
                registeredHeaderClasses.insert(id)
            case .footer:
                registeredFooterClasses.insert(id)
            }
        }
    }

}

// MARK: - UICollectionViewDataSource
extension SectionsAdapter: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return data.sections.count
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard data.sections.count > section else { return 0 }
        return self.section(at: section).numberOfElements()
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionIndex = indexPath.section
        let itemIndex = indexPath.item
        let section = self.section(at: sectionIndex)
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

        if !isCellRegistered(reuseId) {
            registerAction(cellClass)
            registeredCellClasses.insert(reuseId)
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseId, for: indexPath)
        section.configure(cell: cell, at: itemIndex)
        return cell
    }

    // MARK: supplementary
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let section = self.section(at: indexPath.section)
        
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
        let section = self.section(at: indexPath.section)
        section.willDisplaySupplementary(supplementaryView: view,
                                         kind: kindType,
                                         at: indexPath.item)
    }

}

// MARK: - UICollectionViewDelegate
extension SectionsAdapter: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = self.section(at: indexPath.section)
        section.select(at: indexPath.item)
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let section = self.section(at: indexPath.section)
        section.willDisplayCell(at: indexPath.item)
    }

}

// MARK: - UICollectionViewFlowLayout
extension SectionsAdapter: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let section = self.section(at: section)
        return section.insets
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let section = self.section(at: section)
        return section.minimumLineSpacing
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let section = self.section(at: section)
        return section.minimumInterItemSpacing
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let section = self.section(at: indexPath.section)
        let index = indexPath.item
        let insets = section.insets
        let contentWidth = collectionView.bounds.width - insets.left - insets.right

        let sizeCalculation = section.sizeForCell(at: index, contentWidth: contentWidth)
        return self.calculateCellSize(type: sizeCalculation,
                                      section: section,
                                      index: index,
                                      contentWidth: contentWidth)
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
        let section = self.section(at: section)
        guard let viewType = section.supplementaryType(for: kind) else {
            return .zero
        }
        let insets = section.insets
        let contentWidth = collectionView.bounds.width - insets.left - insets.right
        let sizeCalculation = section.sizeForSupplementary(of: kind, contentWidth: contentWidth)
        switch sizeCalculation {
        case .specific(let size):
            return size
        case .automaticHeight(let width):
            let calculationView = self.calculationSupplementaryView(for: viewType,
                                                                    collectionView: collectionView)
            calculationView.prepareForReuse()
            section.configure(supplementaryView: calculationView, kind: kind, at: 0)
            calculationView.updateConstraintsIfNeeded()

            let size = calculationView.systemLayoutSizeFitting(
                CGSize(width: width ?? contentWidth,
                       height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            
            return CGSize(width: contentWidth, height: size.height.rounded(.up))
        case .automaticWidth(let height):
            let calculationView = self.calculationSupplementaryView(for: viewType,
                                                                    collectionView: collectionView)
            calculationView.prepareForReuse()
            section.configure(supplementaryView: calculationView, kind: kind, at: 0)
            calculationView.updateConstraintsIfNeeded()

            let size = calculationView.systemLayoutSizeFitting(
                CGSize(width: UIView.layoutFittingCompressedSize.width,
                       height: height),
                withHorizontalFittingPriority: .fittingSizeLevel,
                verticalFittingPriority: .required
            )
            
            return CGSize(width: size.width.rounded(.up), height: height)
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
    
    /// Perform animatable data reloading for the UICollectionView
    /// - Parameters:
    ///   - ignoreSections: Ignore some specific sections
    ///   - completion: The completion handler
    public func reloadAnimated(
        ignoreSections: [SectionPresentable],
        completion: Completion? = nil
    ) {
        performReload(
            animated: true,
            ignoreSections: ignoreSections,
            completion: completion
        )
    }
    
    /// Perform data reloading for the UICollectionView
    /// - Parameters:
    ///   - animated: Use animation for reloading
    ///   - completion: The completion handler
    public func reloadData(
        animated: Bool,
        completion: Completion? = nil
    ) {
        performReload(
            animated: animated,
            ignoreSections: [],
            completion: completion)
    }

    public func performUpdates(
        _ updates: UICollectionSectionUpdates,
        section: SectionPresentable,
        completion: Completion?
    ) {
        guard let sectionIndex = data.sectionsMap[section.id] else {
            return
        }

        var batchUpdates = UICollectionUpdates()
        batchUpdates = batchUpdates.update(with: updates, section: sectionIndex)
        let reloadParams = ReloadParameters(updates: batchUpdates, fullReload: false, animated: true)
        addUpdate(reloadParams, completions: completion.map { [$0] })
    }

    public func reload(section: SectionPresentable, animated: Bool, completion: Completion? =  nil) {
        guard let sectionIndex = data.sectionsMap[section.id] else {
            return
        }
        let reloadParams: ReloadParameters
        if animated {
            let update = UICollectionUpdates(reloadSections: [sectionIndex])
            reloadParams = ReloadParameters(updates: update, fullReload: false, animated: true)
        } else {
            reloadParams = ReloadParameters(fullReload: true, animated: false)
        }
        addUpdate(reloadParams, completions: completion.map { [$0] })
    }

    public func endRefreshing() {
        guard let collectionView = collectionView, #available(iOS 10.0, *) else { return }

        DispatchQueue.main.async {
            collectionView.refreshControl?.endRefreshing()
        }
    }
    
    // MARK: private
    
    /// Start to reload the UICollectionView
    /// - Parameters:
    ///   - animated: Should use animation
    ///   - ignoreSections: Sections ignored to reload (Only for animated relaoding)
    ///   - completion: The completion handler
    private func performReload(
        animated: Bool,
        ignoreSections: [SectionPresentable],
        completion: Completion?
    ) {
        guard let dataSource = dataSource else {
            completion?(false)
            return
        }

        let newGroups = dataSource.sectionGroups()
        let mewData = SectionsData(groups: newGroups)
        var updates: ReloadParameters
        if animated, #available(iOS 13, *) {
            let oldSections = self.data.sections
            let diff = mewData.sections.difference(from: oldSections) { (l, r) -> Bool in
                return l.id == r.id
            }
            
            var batchUpdates = UICollectionUpdates(diff: diff)
            var reloadIndices = Array(0..<oldSections.count)
            if !ignoreSections.isEmpty {
                let ignoreIds = Set(ignoreSections.map { $0.id })
                reloadIndices = reloadIndices.filter { sectionIndex in
                    !ignoreIds.contains(oldSections[sectionIndex].id)
                }
            }
            let reloads = UICollectionUpdates(
                reloadSections: IndexSet(reloadIndices)
            )
            batchUpdates = batchUpdates.merge(with: reloads)
            updates = ReloadParameters(updates: batchUpdates, animated: true)
        } else {
            updates = ReloadParameters(fullReload: true, animated: false)
        }
        updates.setDataUpdate(mewData)

        addUpdate(updates, completions: completion.map { [$0] })
    }

    func addUpdate(_ update: ReloadParameters, completions: [Completion]?) {
        if case .updating(let previousCompletion) = state {
            // wait for completion and reload fully
            state = .updating { [weak self] _ in
                var update = update
                update.setFullReload()
                self?.addUpdate(update, completions: (previousCompletion.map { [$0] } ?? []) + (completions ?? []))
            }
            return
        } else {
            state = .updating()
        }
        
        if let dataUpdate = update.dataUpdate {
            self.data.sections
                .filter { !dataUpdate.sectionIds.contains($0.id) }
                .forEach { $0.sectionsContext = nil }
            self.data.groups
                .filter { !dataUpdate.groupIds.contains($0.id) }
                .forEach { $0.sectionsContext = nil }
            dataUpdate.groups
                .filter { $0.sectionsContext !== self }
                .forEach { $0.sectionsContext = self }
            dataUpdate.sections
                .filter { $0.sectionsContext !== self }
                .forEach { $0.sectionsContext = self }
            
            self.data = dataUpdate
        }

        let doCompletion: (Bool) -> Void = { [weak self] finished in
            let currentState = self?.state
            self?.state = .idle
            
            completions?.forEach { $0(finished) }
            
            if case .updating(let updateCompletion) = currentState {
                updateCompletion?(finished)
            }
        }

        // Dont use animations when we are not in the window hierarchy
        if update.fullReload || self.collectionView?.window == nil {
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            self.collectionView?.reloadData()
            self.collectionView?.collectionViewLayout.invalidateLayout()
            self.collectionView?.layoutIfNeeded()
            CATransaction.commit()

            doCompletion(true)
        } else {
            let action: () -> () = {
                self.collectionView?.performOrReload(updates: update.updates, with: Void()) { result in
                    doCompletion(result)
                }
            }
            if update.animated {
                action()
            } else {
                UIView.performWithoutAnimation(action)
            }
        }
    }

}

// MARK: - Internal
extension SectionsAdapter {
    
    func calculateCellSize(type: SizeCalculation,
                           section: SectionPresentable,
                           index: Int,
                           contentWidth: CGFloat) -> CGSize {
        switch type {
        case .specific(let size):
            return size
        case .automaticHeight(let width):
            let calculationCell = self.calculationCell(for: section.cellType(at: index), collectionView: collectionView ?? UICollectionView())
            calculationCell.prepareForReuse()
            section.configure(cell: calculationCell, at: index)
            calculationCell.updateConstraints()
            
            let size = calculationCell.contentView.systemLayoutSizeFitting(
                CGSize(width: width ?? contentWidth,
                       height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            
            return CGSize(width: contentWidth, height: size.height.rounded(.up))
        case .automaticWidth(let height):
            let calculationCell = self.calculationCell(for: section.cellType(at: index), collectionView: collectionView ?? UICollectionView())
            calculationCell.prepareForReuse()
            section.configure(cell: calculationCell, at: index)
            calculationCell.updateConstraints()
            
            let size = calculationCell.contentView.systemLayoutSizeFitting(
                CGSize(width: UIView.layoutFittingCompressedSize.width,
                       height: height),
                withHorizontalFittingPriority: .fittingSizeLevel,
                verticalFittingPriority: .required
            )
            
            return CGSize(width: size.width.rounded(.up), height: height)
        }
    }
    
}

// MARK: - SectionsDisplayable
extension SectionsAdapter: SectionsDisplayable {

    public var scrollView: UIScrollView? {
        return collectionView
    }

    public func cellForItem(at index: Int, section: SectionPresentable) -> UICollectionViewCell? {
        guard let sectionIndex = data.sectionsMap[section.id] else {
            return nil
        }
        let indexPath = IndexPath(item: index, section: sectionIndex)
        return collectionView?.cellForItem(at: indexPath)
    }

    public func indexForCell(_ cell: UICollectionViewCell, section: SectionPresentable) -> Int? {
        return collectionView?.indexPath(for: cell)?.item
    }

    public func updateLayout(section: SectionPresentable, at indexes: [Int]?) {
        guard let sectionIndex = data.sectionsMap[section.id] else {
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
        guard let sectionIndex = data.sectionsMap[section.id], let collectionView = collectionView else {
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
        guard let sectionIndex = data.sectionsMap[section.id], let collectionView = collectionView else {
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

    public func rectForCell(at index: Int, section: SectionPresentable) -> CGRect? {
        guard let sectionIndex = data.sectionsMap[section.id], let collectionView = collectionView, let attributes = collectionView.layoutAttributesForItem(at: IndexPath(item: index, section: sectionIndex)) else {
            return nil
        }

        return attributes.frame
    }

    public func rectForSupplementary(kind: SectionSupplementaryKind, index: Int, section: SectionPresentable) -> CGRect? {
        guard let sectionIndex = data.sectionsMap[section.id], let collectionView = collectionView else {
            return nil
        }
        let ip = IndexPath(item: index, section: sectionIndex)
        return collectionView.layoutAttributesForSupplementaryElement(ofKind: kind.value, at: ip)?.frame
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
