import UIKit

public struct TextStyle {
    public let color: UIColor
    public let font: UIFont
    public let alignment: NSTextAlignment
    public let lineHeight: CGFloat
    public let letterSpacing: CGFloat
    public let textTransform: (String) -> String
    public let styleTransform: (UIView, TextStyle) -> TextStyle
    public let additionalAttributes: [NSAttributedString.Key: Any]

    public init(
        color: UIColor,
        font: UIFont,
        alignment: NSTextAlignment,
        lineHeight: CGFloat,
        letterSpacing: CGFloat,
        textTransform: @escaping (String) -> String = { $0 },
        styleTransform: @escaping (UIView, TextStyle) -> TextStyle = { $1 },
        additionalAttributes: [NSAttributedString.Key: Any] = [:]
    ) {
        self.color = color
        self.font = font
        self.alignment = alignment
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
        self.textTransform = textTransform
        self.styleTransform = styleTransform
        self.additionalAttributes = additionalAttributes
    }
}

public protocol TextStyleApplicable {
    @discardableResult
    func apply(textStyle style: TextStyle) -> Self
}

extension StyledLabel: TextStyleApplicable {
    @discardableResult
    public func apply(textStyle style: TextStyle) -> Self {
        dynamicCustomizations.append { [weak self] _ in
            guard let self = self else { return }
            self.attributedText = self.text?.styled(using: style.styleTransform(self, style))
        }
        return self
    }
}

extension StyledTextView: TextStyleApplicable {
    @discardableResult
    public func apply(textStyle style: TextStyle) -> Self {
        font = style.font
        textColor = style.color
        textAlignment = style.alignment
        return self
    }
}

extension StyledTextField: TextStyleApplicable {
    @discardableResult
    public func apply(textStyle style: TextStyle) -> Self {
        font = style.font
        textColor = style.color
        textAlignment = style.alignment
        tintColor = style.color
        return self
    }

    @discardableResult
    public func apply(placeholderStyle style: TextStyle) -> Self {
        dynamicCustomizations.append { [weak self] _  in
            self?.attributedPlaceholder = self?.placeholder?.styled(using: style)
        }
        return self
    }
}

extension TextStyle {
    public var attributes: [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.minimumLineHeight = lineHeight
        paragraph.lineBreakMode = .byTruncatingTail
        return [
            .foregroundColor: color,
            .font: font,
            .kern: letterSpacing,
            .paragraphStyle: paragraph
        ].merging(additionalAttributes, uniquingKeysWith: { $1 })
    }
}

extension String {
    public func styled(using style: TextStyle) -> NSAttributedString {
        return NSAttributedString(string: style.textTransform(self), attributes: style.attributes)
    }
}

public enum TextStyleModifier {
    case color(UIColor)
    case font(UIFont)
    case alignment(NSTextAlignment)
    case lineHeight(CGFloat)
    case letterSpacing(CGFloat)
    case textTransform((String) -> String)
    case styleTransform((UIView, TextStyle) -> TextStyle)
    case additionalAttributes([NSAttributedString.Key: Any])

    public static let uppercased = TextStyleModifier.textTransform { $0.localizedUppercase }
    public static let underlined = TextStyleModifier.additionalAttributes([.underlineStyle: true])
}

public func & (left: TextStyle, right: TextStyleModifier) -> TextStyle {
    return TextStyle(
        color: { if case .color(let color) = right { return color }; return left.color }(),
        font: { if case .font(let font) = right { return font }; return left.font }(),
        alignment: { if case .alignment(let alignment) = right { return alignment }; return left.alignment }(),
        lineHeight: { if case .lineHeight(let lineHeight) = right { return lineHeight }; return left.lineHeight }(),
        letterSpacing: { if case .letterSpacing(let spacing) = right { return spacing }; return left.letterSpacing }(),
        textTransform: {
            if case .textTransform(let transform) = right { return transform }; return left.textTransform
        }(),
        styleTransform: {
            if case .styleTransform(let closure) = right { return closure }; return left.styleTransform
        }(),
        additionalAttributes: {
            if case .additionalAttributes(let dict) = right { return dict }; return left.additionalAttributes
        }()
    )
}

public func & (left: ButtonStyle, right: TextStyleModifier) -> ButtonStyle {
    guard let textStyle = left.textStyle else { return left }
    return ButtonStyle(
        textStyle: { textStyle($0) & right },
        tintColor: { textStyle($0).color },
        backgroundImage: left.backgroundImage,
        iconColor: { textStyle($0).color }
    )
}
