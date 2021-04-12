import UIKit
import SnapKit

public class BorderStyle {
    func apply<T>(to view: T) where T: DynamicStyleApplicableView { fatalError() }
}

extension DynamicStyleApplicable where Self: UIView {
    @discardableResult
    public func apply(borderStyle style: BorderStyle) -> Self {
        style.apply(to: self)
        return self
    }
}

extension BorderStyle {
    static func stroked(with color: UIColor, width: CGFloat = 1) -> BorderStyle {
        StrokedBorderStyle(color: color, width: width)
    }
}

class RadiusBorderStyle: BorderStyle {
    let radius: CGFloat
    let corners: CACornerMask

    init(radius: CGFloat, corners: CACornerMask) {
        self.radius = radius
        self.corners = corners
    }

    override func apply<T>(to view: T) where T: DynamicStyleApplicableView {
        view.layer.cornerRadius = radius
        view.layer.maskedCorners = corners
        view.dynamicCustomizations.append { view in
            view.layer.sublayers?
                .filter { $0.frame == view.layer.bounds && !($0 is CATransformLayer) }
                .forEach {
                    $0.cornerRadius = view.layer.cornerRadius
                    $0.maskedCorners = view.layer.maskedCorners
                }
        }
    }
}

class CircleBorderStyle: BorderStyle {
    override func apply<T>(to view: T) where T: DynamicStyleApplicableView {
        view.dynamicCustomizations.append { view in
            view.layer.cornerRadius = min(view.frame.width, view.frame.height)/2
            view.layer.sublayers?
                .filter { $0.frame == view.layer.bounds && !($0 is CATransformLayer) }
                .forEach { $0.cornerRadius = view.layer.cornerRadius }
        }
    }
}

class StrokedBorderStyle: BorderStyle {
    private let color: UIColor
    private let width: CGFloat

    init(color: UIColor, width: CGFloat) {
        self.color = color
        self.width = width
    }

    override func apply<T>(to view: T) where T: DynamicStyleApplicableView {
        view.layer.borderWidth = width
        view.layer.borderColor = color.cgColor
    }
}

class DashedBorderStyle: BorderStyle {
    private let color: UIColor
    private let width: CGFloat

    init(color: UIColor, width: CGFloat) {
        self.color = color
        self.width = width
    }

    override func apply<T>(to view: T) where T: DynamicStyleApplicableView {
        let border = CAShapeLayer()
        border.lineDashPattern = [3, 3]
        border.strokeColor = color.cgColor
        border.lineWidth = width
        border.fillColor = nil
        view.layer.addSublayer(border)

        view.dynamicCustomizations.append { _ in
            border.frame = view.bounds
            border.path = UIBezierPath(roundedRect: view.bounds, cornerRadius: view.layer.cornerRadius).cgPath
        }
    }
}

class ColoredBorderStyle: BorderStyle {
    let color: UIColor
    let weight: UIEdgeInsets

    init(color: UIColor, weight: UIEdgeInsets) {
        self.color = color
        self.weight = weight
    }

    override func apply<T>(to view: T) where T: DynamicStyleApplicableView {
        let borders = View().apply {
            $0.backgroundColor = .clear
            $0.color = color
            $0.insets = weight
            $0.isOpaque = false
            $0.clipsToBounds = true
        }
        view.addSubview(borders)
        borders.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    class View: UIView, StylingView {
        var color: UIColor = .clear {
            didSet { setNeedsDisplay() }
        }
        var insets: UIEdgeInsets = .zero {
            didSet { setNeedsDisplay() }
        }
        override var frame: CGRect {
            didSet { setNeedsDisplay() }
        }
        override func draw(_ rect: CGRect) {
            color.setFill()
            UIRectFill(rect)
            backgroundColor?.setFill()
            UIRectFill(rect.inset(by: insets))
        }
    }
}

final class ComposedBorderStyle: BorderStyle {
    let styles: [BorderStyle]

    init(_ styles: [BorderStyle]) {
        self.styles = styles
    }

    override func apply<T>(to view: T) where T: DynamicStyleApplicableView {
        styles.forEach { $0.apply(to: view) }
    }
}

extension BorderStyle {
    public static func + (lhs: BorderStyle, rhs: BorderStyle) -> BorderStyle {
        return ComposedBorderStyle([lhs, rhs])
    }
}
