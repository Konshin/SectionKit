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

/// Источник данных для секций
public protocol SectionsAdapterDataSource: class {

    /// Список секций
    func sections() -> [SectionPresentable]

}

/// Протокол для связи секций и коллекции
public protocol SectionsDisplayable: class {

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
    /// Проскроллить до ячейки
    func scrollToItem(_ section: SectionPresentable, index: Int, at position: UICollectionView.ScrollPosition, animated: Bool)
    /// Проскроллить до хедера/футера
    func scrollToSupplementary(_ section: SectionPresentable,
                               kind: SectionSupplementaryKind,
                               index: Int,
                               at position: UICollectionView.ScrollPosition,
                               animated: Bool)

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
public enum SizeCalculation {
    case automatic
    case specific(CGSize)
    
    public static let zero: SizeCalculation = .specific(.zero)
}
