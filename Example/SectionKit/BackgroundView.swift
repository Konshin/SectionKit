//
//  BackgroundView.swift
//  SectionKit_Example
//
//  Created by a.konshin on 09.08.2022.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

final class BackgroundView: UICollectionReusableView {
    
    static let reuseId = "BackgroundView"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let coloredView = UIView()
        if #available(iOS 13.0, *) {
            coloredView.backgroundColor = UIColor.systemGray4
        } else {
            coloredView.backgroundColor = .lightGray
        }
        coloredView.layer.cornerRadius = 16
        
        addSubview(coloredView)
        coloredView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            coloredView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            coloredView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            coloredView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            coloredView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
