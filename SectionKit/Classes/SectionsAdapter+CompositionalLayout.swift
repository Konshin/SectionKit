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
    
    private struct LayoutCalculation {
        let frames: [CGRect]
        let maxX: CGFloat
        let maxY: CGFloat
    }
    
    @available(iOS 13.0, *)
    private func layoutCalculation(
        section: SectionPresentable,
        contentWidth: CGFloat,
        env: NSCollectionLayoutEnvironment
    ) -> LayoutCalculation {
        let isOrthogonal = section.orthogonalScrollingBehavior != .none
        
        var originX: CGFloat = 0
        var originY: CGFloat = 0
        var lastItemLength: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        var frames = [CGRect]()
        for idx in 0..<section.numberOfElements() {
            let sizeCalculation = section.sizeForCell(at: idx, contentWidth: contentWidth)
            let size = self.calculateCellSize(
                type: sizeCalculation,
                section: section,
                index: idx,
                contentWidth: contentWidth
            )
            if !isOrthogonal, originX > 0, size.width + originX > contentWidth {
                originY += lastItemLength + section.minimumLineSpacing
                originX = 0
                lastItemLength = 0
            }
            let rect = CGRect(
                x: originX,
                y: originY,
                width: size.width,
                height: size.height
            )
            if isOrthogonal {
                lastItemLength = max(lastItemLength, rect.width)
                originX += rect.width + section.minimumLineSpacing
                maxHeight = max(maxHeight, size.height)
            } else {
                lastItemLength = max(lastItemLength, rect.height)
                originX += rect.width + section.minimumInterItemSpacing
            }
            frames.append(rect)
        }
        return LayoutCalculation(
            frames: frames,
            maxX: isOrthogonal ? (originX - section.minimumLineSpacing) : contentWidth,
            maxY: isOrthogonal ? maxHeight : originY + lastItemLength
        )
    }
    
    @available(iOS 13.0, *)
    private func layoutGroup(section: SectionPresentable, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutGroup {
        if let described = section.compositionalLayoutGroup(environment: environment) {
            return described
        } else {
            let isOrthogonal = section.orthogonalScrollingBehavior != .none
            if isOrthogonal {
                // Calculate via the first item
                let contentWidth = self.contentWidth(for: section, environment: environment)
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
            } else {
                let calculation = layoutCalculation(
                    section: section,
                    contentWidth: self.contentWidth(for: section, environment: environment),
                    env: environment
                )
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(
                        calculation.maxX
                    ),
                    heightDimension: .absolute(
                        calculation.maxY
                    )
                )

                return NSCollectionLayoutGroup.custom(layoutSize: groupSize) { _ in
                    return calculation.frames.map { frame in
                        NSCollectionLayoutGroupCustomItem(frame: frame)
                    }
                }
            }
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
    
    @available(iOS 13.0, *)
    private func contentWidth(for section: SectionPresentable, environment: NSCollectionLayoutEnvironment) -> CGFloat {
        let insets = section.insets
        return environment.container.effectiveContentSize.width - insets.left - insets.right
    }
    
}
