import UIKit

public struct ButtonStyle {
    public let textStyle: ((UIButton.State) -> TextStyle)?
    public let tintColor: (UIButton.State) -> UIColor
    public let backgroundImage: (UIButton.State) -> UIImage?
    public let iconColor: (UIButton.State) -> UIColor
}

public protocol ButtonStyleApplicable {
    @discardableResult
    func apply(buttonStyle style: ButtonStyle) -> Self
}

open class StyledButton: UIButton, DynamicStyleApplicable, ButtonStyleApplicable {
    public var dynamicCustomizations = [(DynamicStyleApplicableView) -> Void]()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        dynamicCustomizations.forEach { $0(self) }
    }

    public var title: String? {
        get { title(for: .normal) }
        set { setTitle(newValue, for: .normal) }
    }

    public var image: UIImage? {
        didSet { updateStyle() }
    }

    public var action: () -> Void = {}

    private var style: ButtonStyle? {
        didSet { updateStyle() }
    }

    open func setup() {
        addTarget(self, action: #selector(performAction), for: .touchUpInside)
    }

    @objc private func performAction() { action() }

    private func updateStyle() {
        guard let style = style else { return }
        UIControl.State.allCases.forEach {
            setBackgroundImage(style.backgroundImage($0), for: $0)
            setImage(image, for: $0)
            if let textStyle = style.textStyle {
                setAttributedTitle(title(for: $0)?.styled(using: textStyle($0)), for: $0)
            }
        }
    }

    @discardableResult
    public func apply(buttonStyle style: ButtonStyle) -> Self {
        self.style = style
        return self
    }

    open override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
        updateStyle()
    }
}

private extension UIControl.State {
    static let allCases = [
        UIControl.State.application, .disabled, .focused, .highlighted, .normal, .reserved, .selected
    ]
}
