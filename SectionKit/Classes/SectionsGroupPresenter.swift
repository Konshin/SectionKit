//
//  SectionsGroupPresenter.swift
//  SocialTrading
//
//  Created by Aleksei Konshin on 09.06.2020.
//  Copyright © 2020 com.exness. All rights reserved.
//

import UIKit
import UICollectionUpdates

public protocol SectionsGroupDisplayable: SectionsDisplayable {

    func reloadData(animated: Bool, completion: SectionsAdapter.Completion?)

    func performUpdates(_ updates: UICollectionUpdates, since firstSection: SectionPresentable)

}

public extension SectionsGroupDisplayable {

    func reloadData(animated: Bool, completion: SectionsAdapter.Completion? = nil) {
        reloadData(animated: animated, completion: completion)
    }

}

public protocol SectionsGroupPresenter {

    var sectionsContext: SectionsGroupDisplayable? { get set }

    var presenters: [SectionPresentable] { get }

}
