//
//  TestSection.swift
//  SectionKit_Example
//
//  Created by Aleksei Konshin on 02.07.2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import SectionKit

final class TestSection: SectionPresentable {
    
    var sectionsContext: SectionsDisplayable?
    
    func numberOfElements() -> Int {
        return 1
    }
    
    func cellType(at index: Int) -> SectionReusableViewType<UICollectionViewCell> {
        return .code(UICollectionViewCell.self)
    }
    
    func configure(cell: UICollectionViewCell, at index: Int) {
        
    }
    
    func select(at index: Int) {
        print("Did select cell at index: \(index)")
    }
    
    func sizeForCell(at index: Int, contentWidth: CGFloat) -> SizeCalculation {
        .automatic
    }
    
}
