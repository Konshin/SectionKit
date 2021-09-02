//
//  SectionsAdapterEntities.swift
//  SocialTrading
//
//  Created by Aleksei Konshin on 19.11.2019.
//  Copyright © 2019 com.exness. All rights reserved.
//

import UIKit
import UICollectionUpdates

func className(_ class: AnyClass) -> String {
    return NSStringFromClass(`class`).components(separatedBy: ".").last!
}

@available(*, deprecated, message: "Use SectionsGroupPresentable instead")
public typealias SectionsGroupPresenter = SectionsGroupPresentable

/// Datasource for SectionsAdapter
public protocol SectionsAdapterDataSource: AnyObject {
    
    /// List of groups that handles SectionPresentables
    /// If this method is implemented - method `sections()` will be ignored
    ///
    /// # Notes:
    /// The groups will be stored with strong reference
    func sectionGroups() -> [SectionsGroupPresentable]

    /// List of sections
    /// # Notes:
    /// Is better to provide sectionGroups()
    func sections() -> [SectionPresentable]

}

extension SectionsAdapterDataSource {
    
    public func sections() -> [SectionPresentable] {
        return []
    }
    
    public func sectionGroups() -> [SectionsGroupPresentable] {
        return [CommonSectionsGroupPresenter(sections())]
    }
    
}

/// Common sections group presenter
public class CommonSectionsGroupPresenter: SectionsGroupPresentable {

    public let sections: [SectionPresentable]
    public weak var sectionsContext: SectionsGroupDisplayable?
    
    public init(_ sections: [SectionPresentable]) {
        self.sections = sections
    }
    
}

public protocol SectionsScrollable: AnyObject {
    /// Проскроллить до ячейки
    func scrollToItem(_ section: SectionPresentable, index: Int, at position: UICollectionView.ScrollPosition, animated: Bool)
    /// Проскроллить до хедера/футера
    func scrollToSupplementary(_ section: SectionPresentable,
                               kind: SectionSupplementaryKind,
                               index: Int,
                               at position: UICollectionView.ScrollPosition,
                               animated: Bool)
}

/// The interface for connect SectionPresentable and UICollectionView
public protocol SectionsDisplayable: SectionsScrollable {

    /// Получение ячейки по индексу
    func cellForItem(at index: Int, section: SectionPresentable) -> UICollectionViewCell?
    /// Получение индекса по ячейке
    func indexForCell(_ cell: UICollectionViewCell, section: SectionPresentable) -> Int?
    /// Выполнить список обновлений
    func performUpdates(_ updates: UICollectionSectionUpdates, section: SectionPresentable, completion: SectionsAdapter.Completion?)
    /// Перезагрузить секцию
    func reload(section: SectionPresentable, animated: Bool, completion: SectionsAdapter.Completion?)
    /// Обновить лаяут
    func updateLayout(section: SectionPresentable, at indexes: [Int]?)

    /// Ссылка на контроллер
    /// Для показа алертов и тд
    var viewController: UIViewController? { get }

    /// Ссылка на коллекшен для получения информации о жестах и тд...
    var scrollView: UIScrollView? { get }

    /// Фрейм для отображенной ячейки
    func rectForCell(at index: Int, section: SectionPresentable) -> CGRect?
    /// Фрейм для отображенного header / footer
    func rectForSupplementary(kind: SectionSupplementaryKind, index: Int, section: SectionPresentable) -> CGRect?

}

// MARK: - Default implementations
public extension SectionsDisplayable {

    func performUpdates(_ updates: UICollectionSectionUpdates, section: SectionPresentable) {
        performUpdates(updates, section: section, completion: nil)
    }

    func reload(section: SectionPresentable, animated: Bool) {
        reload(section: section, animated: animated, completion: nil)
    }

    /// Rect for all visible elements of the section
    /// - Parameter section: section
    /// - Returns: rect
    func rectForSection(_ section: SectionPresentable) -> CGRect? {
        let rectForFirstElement: CGRect
        let numberOfElements = section.numberOfElements()
        if let rectForHeader = rectForSupplementary(kind: .header, index: 0, section: section), rectForHeader.size != .zero {
            rectForFirstElement = rectForHeader
        } else if numberOfElements > 0, let rectForFirstCell = rectForCell(at: 0, section: section), rectForFirstCell.size != .zero {
            rectForFirstElement = rectForFirstCell
        } else {
            return nil
        }
        let rectForLastElement: CGRect
        if let rectForFooter = rectForSupplementary(kind: .footer, index: 0, section: section), rectForFooter.size != .zero {
            rectForLastElement = rectForFooter
        } else if numberOfElements > 0, let rectForLastCell = rectForCell(at: numberOfElements - 1, section: section), rectForLastCell.size != .zero {
            rectForLastElement = rectForLastCell
        } else {
            return nil
        }

        let unionRect = rectForFirstElement.union(rectForLastElement)
        let sectionInset = section.insets
        return unionRect.inset(by: UIEdgeInsets(top: -sectionInset.top,
                                                left: -sectionInset.left,
                                                bottom: -sectionInset.bottom,
                                                right: -sectionInset.right))
    }

}

/// Type of supplementary view
public enum SectionSupplementaryKind {
    case header
    case footer

    var value: String {
        switch self {
        case .header:
            return UICollectionView.elementKindSectionHeader
        case .footer:
            return UICollectionView.elementKindSectionFooter
        }
    }

    public init?(string: String) {
        if let kind = [SectionSupplementaryKind.header, SectionSupplementaryKind.footer].first(where: { $0.value == string }) {
            self = kind
        } else {
            return nil
        }
    }
}

/// Type of view initialization
///
/// - nib: Using xib-file
/// - code: Init from code
public enum SectionReusableViewType<T: UICollectionReusableView> {
    case nib(T.Type)
    case code(T.Type)

    /// The class of view
    var viewClass: T.Type {
        switch self {
        case .nib(let result), .code(let result):
            return result
        }
    }
}

/// Type of calculation for Section View
public enum SizeCalculation: Equatable {
    /// Calculate height depends on width AutoLayout
    /// If width is nil - the contentWidth will be used
    case automaticHeight(width: CGFloat? = nil)
    case automaticWidth(height: CGFloat)
    case specific(CGSize)
    
    public static let zero: SizeCalculation = .specific(.zero)
    
    @available(*, deprecated, message: "Use SizeCalculation.automaticHeight() instead")
    public static let automatic = SizeCalculation.automaticHeight(width: nil)
}

struct SectionsData {
    private(set) var groups: [SectionsGroupPresentable]
    private(set) var groupsMap: [SectionsGroupPresentable.Identifier: Int]
    private(set) var groupIds: Set<SectionsGroupPresentable.Identifier>
    private(set) var groupToSectionIndicesMap: [SectionsGroupPresentable.Identifier: Range<Int>]
    private(set) var sections: [SectionPresentable]
    private(set) var sectionsMap: [SectionPresentable.Identifier: Int]
    private(set) var sectionIds: Set<SectionsGroupPresentable.Identifier>
}

extension SectionsData {
    
    init(groups: [SectionsGroupPresentable]) {
        self.groups = groups
        self.groupsMap = groups.enumerated().reduce(into: [:]) { result, pair in
            result[pair.element.id] = pair.offset
        }
        self.groupIds = Set(groupsMap.keys)
        
        var groupToSectionIndicesMap = [SectionsGroupPresentable.Identifier: Range<Int>]()
        
        self.sections = groups.reduce(into: []) { result, group in
            let sections = group.sections
            groupToSectionIndicesMap[group.id] = result.count..<(result.count + sections.count)
            result.append(contentsOf: sections)
        }
        self.groupToSectionIndicesMap = groupToSectionIndicesMap
        
        self.sectionsMap = sections.enumerated().reduce(into: [:]) { result, pair in
            result[pair.element.id] = pair.offset
        }
        self.sectionIds = Set(sectionsMap.keys)
    }
    
    func update(group: SectionsGroupPresentable) -> SectionsData {
        guard let groupIndex = groupsMap[group.id], let indices = groupToSectionIndicesMap[group.id] else {
            return self
        }
        var result = self
        result.groups[groupIndex] = group
        
        let sections = group.sections
        result.sections.replaceSubrange(indices, with: sections)
        result.sectionsMap = result.sections.enumerated().reduce(into: [:]) { result, pair in
            result[pair.element.id] = pair.offset
        }
        result.groupToSectionIndicesMap[group.id] = indices.startIndex..<(indices.startIndex + sections.count)
        
        return result
    }
    
}

struct ReloadParameters {

    private(set) var updates: UICollectionUpdates = UICollectionUpdates()

    private(set) var fullReload: Bool = false

    private(set) var dataUpdate: SectionsData?
    
    private(set) var animated: Bool

    mutating func addUpdates(_ updates: UICollectionUpdates) {
        guard !fullReload else { return }

        self.updates = self.updates.merge(with: updates)
    }

    mutating func setFullReload() {
        updates = UICollectionUpdates()
        fullReload = true
    }

    mutating func setDataUpdate(_ update: SectionsData?) {
        dataUpdate = update
    }

    func merge(with params: ReloadParameters) -> ReloadParameters {
        let newDataUpdate = params.dataUpdate ?? self.dataUpdate
        if fullReload || params.fullReload {
            return ReloadParameters(updates: UICollectionUpdates(), fullReload: true, dataUpdate: newDataUpdate, animated: false)
        }

        return ReloadParameters(updates: updates.merge(with: params.updates),
                                fullReload: false,
                                dataUpdate: newDataUpdate,
                                animated: animated && params.animated)
    }

}
