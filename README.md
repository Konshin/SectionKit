# SectionKit

[![Version](https://img.shields.io/cocoapods/v/SectionKit.svg?style=flat)](https://cocoapods.org/pods/SectionKit)
[![License](https://img.shields.io/cocoapods/l/SectionKit.svg?style=flat)](https://cocoapods.org/pods/SectionKit)
[![Platform](https://img.shields.io/cocoapods/p/SectionKit.svg?style=flat)](https://cocoapods.org/pods/SectionKit)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## Usage

```swift
final class ViewController: UIViewController, SectionsAdapterDataSource {
    
    private lazy var sectionsAdapter: SectionsAdapter = {
        let adapter = SectionsAdapter(collectionView: collectionView, viewController: self)
        adapter.dataSource = self
        return adapter
    }()
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: self.view.bounds,
                                    collectionViewLayout: UICollectionViewFlowLayout())
        view.backgroundColor = .white
        
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collecitonView.frame = view.bounds
        view.addSubview(collecitonView)
        sectionsAdapter.reloadData(animated: false)
    }

    // MARK: - SectionsAdapterDataSource
    
    func sectionGroups() -> [SectionsGroupPresentable] {
        let sections = (0..<5).map { _ in
            Section()
        }
        return [CommonSectionsGroupPresenter(sections)]
    }
}

final class Cell: UICollectionViewCell {}

final class Section: SectionPresentable {
    
    weak var sectionsContext: SectionsDisplayable?

    var insets: UIEdgeInsets {
        return UIEdgeInsets(top: 12, left: 16, bottom: 8, right: 16)
    }

    func numberOfElements() -> Int {
        return 3
    }
    
    func cellType(at index: Int) -> SectionReusableViewType<UICollectionViewCell> {
        return .code(Cell.self)
    }
    
    func configure(cell: UICollectionViewCell, at index: Int) {
        guard let cell = cell as? Cell else { return }
        
        // configure cell
    }
    
    func select(at index: Int) {
        print("Did select cell at index: \(index)")
    }
    
    func sizeForCell(at index: Int, contentWidth: CGFloat) -> SizeCalculation {
        // Width = collectionView.bounds.width - insets.left - insets.right
        // Height depends on constraints and the content
        return .automaticHeight()
    }
    
}
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

```ruby
# Podfile
use_frameworks!

target 'YOUR_TARGET_NAME' do
    pod 'SectionKit' ~> '1.0.5'
end
```

### [Carthage](https://github.com/Carthage/Carthage)

Add this to `Cartfile`

```
github "konshin/SectionKit" "1.0.5"
```

```bash
$ carthage update --use-xcframeworks
```

## Author

konshin, alexey@konshin.net

## License

SectionKit is available under the MIT license. See the LICENSE file for more info.
