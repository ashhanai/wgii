import UIKit
import SnapKit
import MaterialComponents

final class GasPriceLayout: ScreenLayout {
    let titleLabel = StyledLabel()
    let widget = GasPriceWidgetLayout()
    let separatorView = StyledView()
    let limitSync = SyncStatusLayout()
    let limitTextField = MDCTextField()
    let limitButton = StyledButton()
    lazy var limitButtonWrapper = UIStackView(arrangedSubviews: [limitButton])
    let notificationStatusErrorLabel = StyledLabel()
    let expandingView = StyledView()
    let dataSourceTextView = StyledTextView()

    let limitController = MDCTextInputControllerFilled()

    private lazy var stack = UIStackView(arrangedSubviews: [
        titleLabel, widget, separatorView, limitTextField, limitButtonWrapper, notificationStatusErrorLabel,
        expandingView, dataSourceTextView
    ])

    let safeAreaReferenceView = StyledView()
    let scrollView = StyledScrollView()

    func setup() {
        apply(bgStyle: .color(.secondarySystemBackground))

        addSubview(safeAreaReferenceView)
        addSubview(scrollView)
        scrollView.addSubview(stack)

        let l10n = Localization.Gas.Price.self
        titleLabel.apply {
            $0.text = l10n.title
            $0.font = .systemFont(ofSize: 46, weight: .light)
            $0.textColor = .label
            $0.numberOfLines = 0
            $0.textAlignment = .center
        }

        separatorView.snp.makeConstraints {
            $0.height.equalTo(CGFloat.vSpaceMedium)
        }

        limitTextField.apply {
            $0.placeholder = l10n.Limit.placeholder
            $0.keyboardType = .numberPad
            $0.clearButtonMode = .never
            $0.font = .systemFont(ofSize: 24, weight: .regular)
            $0.trailingView = limitSync
            $0.trailingViewMode = .always
            $0.textColor = .label
        }

        limitController.apply {
            $0.textInput = limitTextField
            $0.activeColor = Asset.Colors.primaryBlue.color
            $0.borderFillColor = .tertiarySystemBackground
            $0.inlinePlaceholderColor = .placeholderText
            $0.floatingPlaceholderNormalColor = .placeholderText
            $0.floatingPlaceholderActiveColor = Asset.Colors.primaryBlue.color
        }

        limitButton.apply {
            $0.setTitleColor(.systemBlue, for: .normal)
            $0.layer.cornerRadius = CGSize.button.height / 2
            $0.clipsToBounds = true
            $0.setTitleColor(.white, for: .normal)
            $0.setTitleColor(.lightText, for: .highlighted)
            $0.setTitleColor(.lightText, for: .disabled)
            $0.setBackgroundImage(UIImage.withColor(Asset.Colors.primaryBlue.color), for: .normal)
            $0.title = l10n.Limit.button
            $0.contentEdgeInsets = .button
        }.snp.makeConstraints {
            $0.size.greaterThanOrEqualTo(CGSize.button)
        }

        limitButtonWrapper.apply {
            $0.axis = .vertical
            $0.alignment = .center
        }

        notificationStatusErrorLabel.apply {
            $0.font = .systemFont(ofSize: 14, weight: .medium)
            $0.textColor = Asset.Colors.primaryRed.color
            $0.textAlignment = .center
            $0.numberOfLines = 0
        }

        expandingView.setContentHuggingPriority(UILayoutPriority(0), for: .vertical)

        dataSourceTextView.apply(bgStyle: .clear).apply {
            $0.isUserInteractionEnabled = true
            $0.textContainerInset = .zero
            $0.isScrollEnabled = false
            $0.isEditable = false
            $0.linkTextAttributes = [.foregroundColor: Asset.Colors.primaryBlue.color]

            let attributedText = NSMutableAttributedString(
                string: l10n.Data.source,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 12, weight: .light),
                    .foregroundColor: UIColor.secondaryLabel,
                    .paragraphStyle: NSMutableParagraphStyle().apply { $0.alignment = .center }
                ]
            )
            let range = attributedText.mutableString.range(of: l10n.Data.Source.link)
            attributedText.addAttribute(.link, value: "https://www.gasnow.org", range: range)
            $0.attributedText = attributedText
        }

        stack.apply {
            $0.axis = .vertical
            $0.spacing = .vSpaceMedium
            $0.isLayoutMarginsRelativeArrangement = true
            $0.layoutMargins = .screen
        }.snp.makeConstraints {
            $0.edges.width.equalToSuperview()
            $0.height.greaterThanOrEqualTo(safeAreaReferenceView.snp.height)
        }

        scrollView.apply {
            $0.keyboardDismissMode = .interactive
            $0.alwaysBounceVertical = true
        }.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        safeAreaReferenceView.snp.makeConstraints {
            $0.edges.equalTo(safeAreaLayoutGuide)
        }
    }
}

final class GasPriceWidgetLayout: ViewLayout {
    let rapid = GasPriceItemLayout()
    let fast = GasPriceItemLayout()
    let standard = GasPriceItemLayout()
    let slow = GasPriceItemLayout()

    let wrapper = StyledView()

    lazy var stack = UIStackView(arrangedSubviews: [rapid, fast, standard, slow])

    func setup() {
        apply(shadowStyle: ShadowStyle(
            radius: 5,
            color: UIColor.black.withAlphaComponent(0.3),
            offset: CGSize(width: 0, height: 5)
        ))
        layer.cornerRadius = .cornerRadius

        addSubview(wrapper)
        wrapper.addSubview(stack)

        let l10n = Localization.Gas.Price.Widget.self
        rapid.titleLabel.text = l10n.rapid
        fast.titleLabel.text = l10n.fast
        standard.titleLabel.text = l10n.standard
        slow.titleLabel.text = l10n.slow

        stack.apply {
            $0.axis = .horizontal
            $0.distribution = .fillEqually
            $0.isLayoutMarginsRelativeArrangement = true
            $0.layoutMargins = .view
        }.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        wrapper
            .apply(bgStyle: .gradient([Asset.Colors.primaryRed.color, Asset.Colors.primaryBlue.color], angle: 90))
            .apply {
                $0.clipsToBounds = true
                $0.layer.cornerRadius = .cornerRadius
            }.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
    }
}

final class GasPriceItemLayout: ViewLayout {
    let valueLabel = StyledLabel()
    let titleLabel = StyledLabel()

    lazy var stack = UIStackView(arrangedSubviews: [valueLabel, titleLabel])

    func setup() {
        addSubview(stack)

        valueLabel.apply {
            $0.font = .systemFont(ofSize: 24, weight: .regular)
            $0.textColor = .white
            $0.textAlignment = .center
        }

        titleLabel.apply {
            $0.font = .systemFont(ofSize: 12, weight: .light)
            $0.textColor = .lightText
            $0.textAlignment = .center
        }

        stack.apply {
            $0.axis = .vertical
            $0.spacing = .vSpaceSmall
        }.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
