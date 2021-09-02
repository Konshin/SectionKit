//
//  SectionPresentable.swift
//  SocialTrading
//
//  Created by akonshin on 07/01/2019.
//  Copyright © 2019 com.exness. All rights reserved.
//

import UIKit

/// A section interface
public protocol SectionPresentable: AnyObject {

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

    // MARK: - UICollectionViewCompositionalLayout
    
    /// Layout description for UICollectionViewCompositionalLayout
    /// If section didn't provide NSCollectionLayoutGroup, the layout will be calculated depending on other methods
    /// - Parameter environment: Layout Environment
    @available(iOS 13.0, *)
    func compositionalLayoutGroup(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutGroup?
    
    @available(iOS 13.0, *)
    var orthogonalScrollingBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior { get }
    
    /// Custom section layout for UICollectionViewCompositionalLayout
    /// - Parameter environment: Layout Environment
    @available(iOS 13.0, *)
    func compositionalLayoutCustomSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection?

}

// MARK: - Default implementation
extension SectionPresentable {

    public var id: Identifier {
        return ObjectIdentifier(self)
    }

    public func supplementaryType(for kind: SectionSupplementaryKind) -> SectionReusableViewType<UICollectionReusableView>? {
        return nil
    }

    public func configure(supplementaryView: UICollectionReusableView,
                   kind: SectionSupplementaryKind,
                   at index: Int) { }

    public func sizeForSupplementary(of kind: SectionSupplementaryKind, contentWidth: CGFloat) -> SizeCalculation {
        return .automaticHeight()
    }

    public func willDisplaySupplementary(supplementaryView: UICollectionReusableView,
                                  kind: SectionSupplementaryKind,
                                  at index: Int) {}

    public func willDisplayCell(at index: Int) {}

    public var insets: UIEdgeInsets {
        return .zero
    }

    public var minimumLineSpacing: CGFloat {
        return 0
    }

    public var minimumInterItemSpacing: CGFloat {
        return 0
    }
    
    @available(iOS 13.0, *)
    public func compositionalLayoutCustomSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        return nil
    }
    
    @available(iOS 13.0, *)
    public func compositionalLayoutGroup(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutGroup? {
        return nil
    }
    
    @available(iOS 13.0, *)
    public var orthogonalScrollingBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior {
        return .none
    }

}
