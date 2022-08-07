//
//  SectionsGroupPresenter.swift
//  SocialTrading
//
//  Created by Aleksei Konshin on 09.06.2020.
//  Copyright © 2020 com.exness. All rights reserved.
//

import UIKit
import UICollectionUpdates

/// An inferface for store list of SectionPresentable
public protocol SectionsGroupPresentable: AnyObject {
    
    typealias Identifier = AnyHashable
    
    /// Unique identifier
    var id: Identifier { get }
    /// Reference for manage the collection
    var sectionsContext: SectionsGroupDisplayable? { get set }
    /// List of sections to display
    var sections: [SectionPresentable] { get }

}

extension SectionsGroupPresentable {
    
    public var id: Identifier {
        return ObjectIdentifier(self)
    }
    
}
