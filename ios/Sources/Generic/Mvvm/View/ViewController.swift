import UIKit
import RxSwift

open class BaseViewController<Layout: ScreenLayout>: UIViewController {
    public let layout = Layout()

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func loadView() {
        view = layout
    }
}

open class ViewController<Layout: ScreenLayout, ViewModel>: BaseViewController<Layout> {
    let disposeBag = DisposeBag()

    public let viewModel: ViewModel

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (viewModel as? Activable)?.isActive = true
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        (viewModel as? Activable)?.isActive = false
    }
}
