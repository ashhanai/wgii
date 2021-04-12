import UIKit

extension CGFloat {
    static let cornerRadius = 16 as CGFloat

    static let vSpaceSmall = 4 as CGFloat
    static let vSpaceMedium = 16 as CGFloat
    static let vSpaceNormal = 30 as CGFloat
}

extension CGSize {
    static let icon = CGSize(width: 28, height: 28)
    static let button = CGSize(width: UIScreen.main.bounds.width / 2, height: 44)
}

extension UIEdgeInsets {
    static let screen = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
    static let view = UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16)
    static let button = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
}
