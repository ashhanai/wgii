import UIKit

public protocol SetupApplicable {}

public extension SetupApplicable {
    @discardableResult
    func apply(setup: (inout Self) -> Void) -> Self {
        var copy = self
        setup(&copy)
        return copy
    }
}

extension NSObject: SetupApplicable {}
extension Array: SetupApplicable {}
extension Dictionary: SetupApplicable {}

public struct Setup<Type> {
    let closure: (Type) -> Void
}

public extension SetupApplicable {
    @discardableResult
    func apply(setup: Setup<Self>) -> Self {
        setup.closure(self)
        return self
    }
}
