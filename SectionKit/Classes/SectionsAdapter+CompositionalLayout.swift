//
//  SectionsAdapter+CompositionalLayout.swift
//  SectionKit
//
//  Created by Aleksei Konshin on 07.05.2021.
//

import UIKit

extension SectionsAdapter {
    
    /// Provider for UICollectionViewCompositionalLayout
    @available(iOS 13.0, *)
    public func compositionalLayoutProvider() -> UICollectionViewCompositionalLayoutSectionProvider {
        return { index, environment in
            let section = self.section(at: index)
            
            let layoutSection: NSCollectionLayoutSection
            if let providedSection = section.compositionalLayoutCustomSection(environment: environment) {
                layoutSection = providedSection
            } else {
                layoutSection = self.createLayoutSection(section: section, environment: environment)
            }
            
            return layoutSection
        }
    }
    
    // MARK: private
    
    @available(iOS 13.0, *)
    private func layoutGroup(section: SectionPresentable, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutGroup {
        if let described = section.compositionalLayoutGroup(environment: environment) {
            return described
        } else {
            let contentWidth = environment.container.effectiveContentSize.width
            let layoutSize: NSCollectionLayoutSize
            if section.numberOfElements() > 0 {
                let sizeType = section.sizeForCell(
                    at: 0,
                    contentWidth: contentWidth
                )
                layoutSize = self.layoutSize(from: sizeType)
            } else {
                layoutSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(1)
                )
            }
            let item = NSCollectionLayoutItem(
                layoutSize: layoutSize
            )
            
            let groupSize = layoutSize
            let group: NSCollectionLayoutGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: [item]
            )
            group.interItemSpacing = .flexible(section.minimumInterItemSpacing)
            return group
        }
    }
    
    @available(iOS 13.0, *)
    private func createLayoutSection(section: SectionPresentable,
                                     environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let group: NSCollectionLayoutGroup = layoutGroup(
            section: section,
            environment: environment
        )
        
        let layoutSection = NSCollectionLayoutSection(group: group)
        layoutSection.interGroupSpacing = section.minimumLineSpacing
        let insets = section.insets
        layoutSection.contentInsets = .init(top: insets.top,
                                            leading: insets.left,
                                            bottom: insets.bottom,
                                            trailing: insets.right)
        layoutSection.orthogonalScrollingBehavior = section.orthogonalScrollingBehavior
        
        let contentWidth = environment.container.effectiveContentSize.width
        
        var supplementaryItems = [NSCollectionLayoutBoundarySupplementaryItem]()
        for kind in [SectionSupplementaryKind.header, SectionSupplementaryKind.footer] {
            if section.supplementaryType(for: kind) != nil {
                let sizeType = section.sizeForSupplementary(
                    of: kind,
                    contentWidth: contentWidth
                )
                let layoutSize = self.layoutSize(from: sizeType)
                let alignment: NSRectAlignment
                switch kind {
                case .header:
                    alignment = .top
                case .footer:
                    alignment = .bottom
                }
                let item = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: layoutSize,
                    elementKind: kind.value,
                    alignment: alignment
                )
                supplementaryItems.append(item)
            }
        }
        layoutSection.boundarySupplementaryItems = supplementaryItems
        
        return layoutSection
    }
    
    @available(iOS 13.0, *)
    private func layoutSize(from sizeType: SizeCalculation) -> NSCollectionLayoutSize {
        switch sizeType {
        case .specific(let size):
            return NSCollectionLayoutSize(
                widthDimension: .absolute(size.width),
                heightDimension: .absolute(size.height)
            )
        case .automaticHeight(let width):
            let widthDimension: NSCollectionLayoutDimension
            if let width = width {
                widthDimension = .absolute(width)
            } else {
                widthDimension = .fractionalWidth(1)
            }
            return NSCollectionLayoutSize(
                widthDimension: widthDimension,
                heightDimension: .estimated(1)
            )
        case .automaticWidth(let height):
            return NSCollectionLayoutSize(
                widthDimension: .estimated(1),
                heightDimension: .absolute(height)
            )
        }
    }
    
}