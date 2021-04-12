import UIKit
import SnapKit

public class BackgroundStyle {
    func apply<T>(to view: T) where T: UIView { fatalError() }
}

public protocol BackgroundStyleApplicable {
    @discardableResult
    func apply(bgStyle style: BackgroundStyle) -> Self
}

extension UIView: BackgroundStyleApplicable {
    @discardableResult
    public func apply(bgStyle style: BackgroundStyle) -> Self {
        style.apply(to: self)
        return self
    }
}

public extension BackgroundStyle {
    static func color(_ color: UIColor) -> BackgroundStyle {
        SolidColorStyle(color: color)
    }
    static func gradient(_ colors: [UIColor], angle: CGFloat) -> BackgroundStyle {
        GradientStyle(colors: colors, angle: angle)
    }
    static func image(named name: String) -> BackgroundStyle {
        ImageStyle(image: UIImage(named: name)!)
    }
    static func pattern(named name: String) -> BackgroundStyle {
        PatternStyle(patternImage: UIImage(named: name)!)
    }
    static func fading(_ color: UIColor, in height: CGFloat = 15) -> BackgroundStyle {
        FadingStyle(color: color, height: height)
    }
}

class SolidColorStyle: BackgroundStyle {
    let color: UIColor
    init(color: UIColor) { self.color = color }

    override func apply<T>(to view: T) where T: UIView {
        view.backgroundColor = color
    }
}

class GradientStyle: BackgroundStyle {
    private let colors: [UIColor]
    private let angle: CGFloat

    init(colors: [UIColor], angle: CGFloat) {
        self.colors = colors
        self.angle = angle
    }

    override func apply<T>(to view: T) where T: UIView {
        let gradientView = GradientView()
        apply(to: gradientView.gradientLayer)
        view.addSubview(gradientView)
        view.sendSubviewToBack(gradientView)
        gradientView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    func apply(to layer: CAGradientLayer) {
        layer.colors = colors.map { $0.cgColor }
        layer.startPoint = CGPoint(
            x: pow(sin(.pi * (angle / 360 + 0.75)), 2),
            y: 1 - pow(sin(.pi * (angle / 360 + 0.00)), 2)
        )
        layer.endPoint = CGPoint(
            x: pow(sin(.pi * (angle / 360 + 0.25)), 2),
            y: 1 - pow(sin(.pi * (angle / 360 + 0.50)), 2)
        )
    }
}

class PatternStyle: BackgroundStyle {
    private let patternImage: UIImage

    init(patternImage: UIImage) {
        self.patternImage = patternImage
    }

    override func apply<T>(to view: T) where T: UIView {
        let patterView = PatternView().apply {
            $0.backgroundColor = UIColor(patternImage: patternImage)
        }
        view.addSubview(patterView)
        view.sendSubviewToBack(patterView)
        patterView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private class PatternView: UIView, StylingView {}
}

private final class GradientView: UIView, StylingView {
    var gradientLayer: CAGradientLayer { return layer as! CAGradientLayer } // swiftlint:disable:this force_cast
    override class var layerClass: AnyClass { return CAGradientLayer.self }
}

class ImageStyle: BackgroundStyle {
    private let image: UIImage

    init(image: UIImage) {
        self.image = image
    }

    override func apply<T>(to view: T) where T: UIView {
        let background = StylingImageView(image: image)
        view.addSubview(background)
        background.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}

private final class StylingImageView: UIImageView, StylingView {}

class FadingStyle: BackgroundStyle {
    private let color: UIColor
    private let height: CGFloat

    init(color: UIColor, height: CGFloat) {
        self.color = color
        self.height = height
    }

    override func apply<T>(to view: T) where T: UIView {
        let background = FadingView().apply {
            $0.top.apply(bgStyle: .gradient([color, color.withAlphaComponent(0)], angle: 0))
            $0.main.backgroundColor = color
            $0.top.snp.makeConstraints { $0.height.equalTo(height) }
        }
        view.addSubview(background)
        background.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}

private final class FadingView: ViewLayout, StylingView {
    let top = StyledView()
    let main = StyledView()
    private lazy var stack = UIStackView(arrangedSubviews: [top, main]).apply { $0.axis = .vertical }

    func setup() {
        addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().priority(.low)
        }
    }
}

private class ComposedBackgroundStyle: BackgroundStyle {
    private let styles: [BackgroundStyle]

    init(_ styles: BackgroundStyle ...) {
        self.styles = styles
    }

    override func apply<T>(to view: T) where T: UIView {
        styles.forEach { $0.apply(to: view) }
    }
}

public extension BackgroundStyle {
    static func + (lhs: BackgroundStyle, rhs: BackgroundStyle) -> BackgroundStyle {
        ComposedBackgroundStyle(lhs, rhs)
    }
}
