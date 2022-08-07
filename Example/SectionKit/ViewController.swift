//
//  ViewController.swift
//  SectionKit
//
//  Created by konshin on 07/02/2020.
//  Copyright (c) 2020 konshin. All rights reserved.
//

import UIKit
import SectionKit

final class ViewController: UIViewController {
    
    private lazy var sectionsAdapter: SectionsAdapter = {
        let adapter = SectionsAdapter(collectionView: nil, viewController: self)
        adapter.dataSource = self
        return adapter
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout: UICollectionViewLayout
        if #available(iOS 13.0, *) {
            layout = UICollectionViewCompositionalLayout(sectionProvider: sectionsAdapter.compositionalLayoutProvider())
        } else {
            layout = UICollectionViewFlowLayout()
        }
        let view = UICollectionView(frame: self.view.bounds,
                                    collectionViewLayout: layout)
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        sectionsAdapter.updateCollectionView(view)
        
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.fill(with: collectionView)
        sectionsAdapter.reloadData(animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: - SectionsAdapterDataSource
extension ViewController: SectionsAdapterDataSource {
    
    func sections() -> [SectionPresentable] {
        return (0..<5).map { _ in
            Section()
        }
    }
    
    func sectionGroups() -> [SectionsGroupPresentable] {
        let sections = (0..<5).map { _ in
            Section()
        }
        return [CommonSectionsGroupPresenter(sections)]
    }
}

extension UIView {
    
    func fill(with subview: UIView, insets: UIEdgeInsets = .zero) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        let leading = subview.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: insets.left)
        let trailing = subview.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -insets.right)
        let top = subview.topAnchor.constraint(equalTo: self.topAnchor, constant: insets.top)
        let bottom = subview.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -insets.bottom)
        
        [leading, trailing, top, bottom]
            .forEach { $0.isActive = true }
    }
    
}

