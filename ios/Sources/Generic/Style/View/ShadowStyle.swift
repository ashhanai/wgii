import UIKit

public struct ShadowStyle {
    public let radius: CGFloat
    public let color: UIColor
    public let offset: CGSize
}

public protocol ShadowStyleApplicable {
    @discardableResult
    func apply(shadowStyle style: ShadowStyle) -> Self
}

extension UIView: ShadowStyleApplicable {
    @discardableResult
    public func apply(shadowStyle style: ShadowStyle) -> Self {
        layer.shadowOpacity = 1
        layer.shadowOffset = style.offset
        layer.shadowColor = style.color.cgColor
        layer.shadowRadius = style.radius
        return self
    }
}
