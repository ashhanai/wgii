import UIKit
import SnapKit

final class SyncStatusLayout: ViewLayout {
    private let loadingIndicator = UIActivityIndicatorView()
    private let doneImageView = StyledImageView()

    private lazy var stack = UIStackView(arrangedSubviews: [loadingIndicator, doneImageView])

    var isSyncing: Bool = false {
        didSet {
            isSyncing ? loadingIndicator.startAnimating() : loadingIndicator.stopAnimating()
            doneImageView.isHidden = isSyncing
        }
    }

    func setup() {
        addSubview(stack)

        loadingIndicator.apply {
            $0.hidesWhenStopped = true
        }

        doneImageView.apply {
            $0.image = Asset.Images.done.image
                .resized(to: .icon)
                .withRenderingMode(.alwaysTemplate)
            $0.tintColor = .label
        }

        stack.apply {
            $0.axis = .horizontal
        }.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
