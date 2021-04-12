import UIKit

public typealias ViewLayout = BaseViewLayout & ViewLayoutProtocol
public typealias ScreenLayout = BaseScreenLayout & ViewLayoutProtocol

public protocol ViewLayoutProtocol {
    func setup()
}

open class BaseViewLayout: StyledView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        (self as? ViewLayoutProtocol)?.setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class BaseScreenLayout: StyledView {
    required public override init(frame: CGRect) {
        super.init(frame: frame)
        (self as? ViewLayoutProtocol)?.setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

