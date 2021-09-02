//
//  SectionsAdapter+SectionsGroupDisplayable.swift
//  NetworkCommon
//
//  Created by Aleksei Konshin on 02.09.2021.
//

import Foundation
import UICollectionUpdates

/// An interfac to connect SectionsGroupPresentable and UICollectionView
public protocol SectionsGroupDisplayable: SectionsScrollable {

    func performGroupUpdates(
        group: SectionsGroupPresentable,
        updates: UICollectionUpdates,
        completion: SectionsAdapter.Completion?
    )
    
    func reloadGroup(
        group: SectionsGroupPresentable,
        ignoreSections: [SectionPresentable],
        animated: Bool,
        completion: SectionsAdapter.Completion?
    )

}

public extension SectionsGroupDisplayable {

    func performGroupUpdates(group: SectionsGroupPresentable, updates: UICollectionUpdates) {
        performGroupUpdates(group: group, updates: updates, completion: nil)
    }
    
    func reloadGroup(
        group: SectionsGroupPresentable,
        ignoreSections: [SectionPresentable] = [],
        animated: Bool
    ) {
        reloadGroup(group: group, ignoreSections: [], animated: animated, completion: nil)
    }

}

extension SectionsAdapter: SectionsGroupDisplayable {
    
    public func performGroupUpdates(
        group: SectionsGroupPresentable,
        updates: UICollectionUpdates,
        completion: Completion?
    ) {
        guard !updates.isEmpty, let firstIndex = data.groupToSectionIndicesMap[group.id]?.lowerBound else {
            return
        }
        
        let newData = self.data.update(group: group)
        let updates = updates.shiftIndexes(sectionsShift: firstIndex)
        
        let reloadParams = ReloadParameters(
            updates: updates,
            fullReload: false,
            dataUpdate: newData,
            animated: true
        )
        addUpdate(reloadParams, completions: completion.map { [$0] } ?? [])
    }
    
    public func reloadGroup(
        group: SectionsGroupPresentable,
        ignoreSections: [SectionPresentable],
        animated: Bool,
        completion: Completion?
    ) {
        let newData = self.data.update(group: group)
        
        let reloadParams: ReloadParameters
        if #available(iOS 13, *) {
            let groupPresentersIds = Set(group.sections.map { $0.id })
            let ignoreIds = data.sections
                .map { $0.id }
                .filter { !groupPresentersIds.contains($0) } + ignoreSections.map { $0.id }
            let updates = self.collectionUpdates(
                oldSections: data.sections,
                newSections: newData.sections,
                ignoreSectionReloads: ignoreIds
            )
            reloadParams = ReloadParameters(
                updates: updates,
                fullReload: false,
                dataUpdate: newData,
                animated: animated
            )
        } else {
            reloadParams = ReloadParameters(fullReload: true, animated: false)
        }
        addUpdate(reloadParams, completions: completion.map { [$0] } ?? [])
    }
    
}
