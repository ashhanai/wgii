import UIKit

public typealias DynamicStyleApplicableView = UIView & DynamicStyleApplicable

public protocol DynamicStyleApplicable: AnyObject {
    var dynamicCustomizations: [(DynamicStyleApplicableView) -> Void] { get set }
}

extension DynamicStyleApplicable {
    @discardableResult
    public func resetDynamicStyles() -> Self {
        dynamicCustomizations = []
        (self as? UIView)?.subviews.filter { $0 is StylingView }.forEach { $0.removeFromSuperview() }
        (self as? UIView)?.setNeedsLayout()
        return self
    }
}

open class StyledLabel: UILabel, DynamicStyleApplicable {
    public var dynamicCustomizations = [(DynamicStyleApplicableView) -> Void]()

    open override func layoutSubviews() {
        super.layoutSubviews()
        dynamicCustomizations.forEach { $0(self) }
    }
}

open class StyledImageView: UIImageView, DynamicStyleApplicable {
    public var dynamicCustomizations = [(DynamicStyleApplicableView) -> Void]()

    open override func layoutSubviews() {
        super.layoutSubviews()
        dynamicCustomizations.forEach { $0(self) }
    }
}

open class StyledView: UIView, DynamicStyleApplicable {
    public var dynamicCustomizations = [(DynamicStyleApplicableView) -> Void]()

    open override func layoutSubviews() {
        super.layoutSubviews()
        dynamicCustomizations.forEach { $0(self) }
    }
}

open class StyledScrollView: UIScrollView, DynamicStyleApplicable {
    public var dynamicCustomizations = [(DynamicStyleApplicableView) -> Void]()

    open override func layoutSubviews() {
        super.layoutSubviews()
        dynamicCustomizations.forEach { $0(self) }
    }
}

open class StyledTableView: UITableView, DynamicStyleApplicable {
    public var dynamicCustomizations = [(DynamicStyleApplicableView) -> Void]()

    open override func layoutSubviews() {
        super.layoutSubviews()
        dynamicCustomizations.forEach { $0(self) }
    }
}

open class StyledCollectionView: UICollectionView, DynamicStyleApplicable {
    public var dynamicCustomizations = [(DynamicStyleApplicableView) -> Void]()

    open override func layoutSubviews() {
        super.layoutSubviews()
        dynamicCustomizations.forEach { $0(self) }
    }
}

open class StyledTextView: UITextView, DynamicStyleApplicable {
    public var dynamicCustomizations = [(DynamicStyleApplicableView) -> Void]()

    open override func layoutSubviews() {
        super.layoutSubviews()
        dynamicCustomizations.forEach { $0(self) }
    }
}

open class StyledTextField: UITextField, DynamicStyleApplicable {
    public var dynamicCustomizations = [(DynamicStyleApplicableView) -> Void]()

    open override func layoutSubviews() {
        super.layoutSubviews()
        dynamicCustomizations.forEach { $0(self) }
    }
}

protocol StylingView {}
