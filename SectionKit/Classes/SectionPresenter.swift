//
//  SectionPresenter.swift
//  SocialTrading
//
//  Created by akonshin on 07/01/2019.
//  Copyright © 2019 com.exness. All rights reserved.
//

import UIKit

/// A section interface
public protocol SectionPresentable: class {

    // MARK: - Nested types

    /// Type of identifier
    typealias Identifier = AnyHashable

    /// A context for link to collection
    /// Must be weak!
    var sectionsContext: SectionsDisplayable? { get set }

    /// Unique identifier
    var id: Identifier { get }
    /// insets for the section
    var insets: UIEdgeInsets { get }

    /// Minimum space between two cells
    /// [Cell] - spacing - [Cell]
    var minimumLineSpacing: CGFloat { get }
    /// Minimum space between two lines of cells
    /// [Cell] [Cell] [Cell]
    ///    - spacing -
    /// [Cell] [Cell] [Cell]
    var minimumInterItemSpacing: CGFloat { get }

    /// Number of cells in the section
    func numberOfElements() -> Int
    /// Type of UICollectionViewCell for index
    func cellType(at index: Int) -> SectionReusableViewType<UICollectionViewCell>
    /// Configuration for a cell at index
    func configure(cell: UICollectionViewCell, at index: Int)

    /// Handle selection of a cell
    func select(at index: Int)
    /// Size calculation for a cell
    func sizeForCell(at index: Int, contentWidth: CGFloat) -> SizeCalculation

    /// Type of UICollectonReusableView
    func supplementaryType(for kind: SectionSupplementaryKind) -> SectionReusableViewType<UICollectionReusableView>?
    /// Configuration for a supplementary view
    func configure(supplementaryView: UICollectionReusableView,
                   kind: SectionSupplementaryKind,
                   at index: Int)
    /// Size calculation for a supplementary view
    func sizeForSupplementary(of kind: SectionSupplementaryKind, contentWidth: CGFloat) -> SizeCalculation
    
    /// Called when the cell will be displayed
    func willDisplayCell(at index: Int)
    /// Called when the supplementary view will be displayed
    func willDisplaySupplementary(supplementaryView: UICollectionReusableView,
                                  kind: SectionSupplementaryKind,
                                  at index: Int)

}

// MARK: - Default implementation
extension SectionPresentable {

    var id: Identifier {
        return ObjectIdentifier(self)
    }

    func supplementaryType(for kind: SectionSupplementaryKind) -> SectionReusableViewType<UICollectionReusableView>? {
        return nil
    }

    func configure(supplementaryView: UICollectionReusableView,
                   kind: SectionSupplementaryKind,
                   at index: Int) { }

    func sizeForSupplementary(of kind: SectionSupplementaryKind, contentWidth: CGFloat) -> SizeCalculation {
        return .automatic
    }

    func willDisplaySupplementary(supplementaryView: UICollectionReusableView,
                                  kind: SectionSupplementaryKind,
                                  at index: Int) {}

    func willDisplayCell(at index: Int) {}

    var insets: UIEdgeInsets {
        return .zero
    }

    var minimumLineSpacing: CGFloat {
        return 0
    }

    var minimumInterItemSpacing: CGFloat {
        return 0
    }

}
