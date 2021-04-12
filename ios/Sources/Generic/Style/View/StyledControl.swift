import UIKit

public final class StyledSwitch: UISwitch {
    public var action: (Bool) -> Void = { _ in }
    public var animatedAction: (Bool) -> Void = { _ in }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addTarget(self, action: #selector(performAction), for: .valueChanged)
    }

    @objc private func performAction() {
        action(isOn)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
            self.animatedAction(self.isOn)
        }
    }
}

public final class StyledSegmentedControl: UISegmentedControl {

    public struct Segment {
        let title: String
        let action: () -> Void
    }

    public var segments: [Segment] = [] {
        didSet { setupSegments() }
    }

    public init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addTarget(self, action: #selector(performAction), for: .valueChanged)
    }

    private func setupSegments() {
        removeAllSegments()
        segments.enumerated().forEach {
            insertSegment(withTitle: $0.element.title, at: $0.offset, animated: false)
        }
    }

    @objc private func performAction() {
        segments[selectedSegmentIndex].action()
    }
}

open class StyledPageControl: UIPageControl, DynamicStyleApplicable {

    public struct Page {
        let action: () -> Void
    }

    public var pages: [Page] = [] {
        didSet { setupPages() }
    }

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

    open func setup() {
        addTarget(self, action: #selector(performAction), for: .valueChanged)
    }

    func setupPages() {
        numberOfPages = pages.count
    }

    @objc private func performAction() { pages[currentPage].action() }
}
