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
    
    var minimumInterItemSpacing: CGFloat {
        return 8
    }
    
    var minimumLineSpacing: CGFloat {
        return 16
    }
    
    var insets: UIEdgeInsets {
        return UIEdgeInsets(top: 40, left: 10, bottom: 20, right: 10)
    }
    
    @available(iOS 13.0, *)
    var orthogonalScrollingBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior {
        return .continuous
    }
    
    func numberOfElements() -> Int {
        return 7
    }
    
    func cellType(at index: Int) -> SectionReusableViewType<UICollectionViewCell> {
        return .code(Cell.self)
    }
    
    func configure(cell: UICollectionViewCell, at index: Int) {
        guard let cell = cell as? Cell else { return }
        
        cell.label.text = "Cell #\(index)"
    }
    
    func select(at index: Int) {
        print("Did select cell at index: \(index)")
    }
    
    func sizeForCell(at index: Int, contentWidth: CGFloat) -> SizeCalculation {
        if index % 3 == 0 {
            return .specific(CGSize(width: contentWidth * 0.2, height: 75))
        } else {
            if #available(iOS 13, *) {
                return .automaticWidth(height: 70)
            } else {
                return .automaticHeight()
            }
        }
    }
    
    func supplementaryType(for kind: SectionSupplementaryKind) -> SectionReusableViewType<UICollectionReusableView>? {
        return .code(Supplementary.self)
    }
    
    func sizeForSupplementary(of kind: SectionSupplementaryKind, contentWidth: CGFloat) -> SizeCalculation {
        return .specific(CGSize(width: 200, height: 80))
    }
    
    func configure(supplementaryView: UICollectionReusableView, kind: SectionSupplementaryKind, at index: Int) {
        guard let view = supplementaryView as? Supplementary else { return }
        
        switch kind {
        case .header:
            view.label.text = "Header"
        case .footer:
            view.label.text = "Footer"
        }
    }
    
}

private final class Cell: UICollectionViewCell {
    
    private(set) lazy var label: UILabel = {
        let view = UILabel()
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        fill(with: label, insets: UIEdgeInsets(top: 10, left: 10, bottom: 25, right: 10))
        
        layer.borderWidth = 1
        layer.cornerRadius = 10
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

private final class Supplementary: UICollectionReusableView {
    
    private(set) lazy var label: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        fill(with: label, insets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 20))
        
        layer.borderWidth = 1
        layer.cornerRadius = 10
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
