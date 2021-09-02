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
    
    var id: Identifier { get }

    var sectionsContext: SectionsGroupDisplayable? { get set }

    var sections: [SectionPresentable] { get }

}

extension SectionsGroupPresentable {
    
    public var id: Identifier {
        return ObjectIdentifier(self)
    }
    
}
