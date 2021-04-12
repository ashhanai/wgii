import UIKit
import RxKeyboard
import RxSwift

final class GasPriceViewController: ViewController<GasPriceLayout, GasPriceViewModel> {
    typealias State = GasPriceViewModel.State

    private let notificationFeedback = UINotificationFeedbackGenerator()

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.observableGasPrice
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.updateGasPrice(with: $0) })
            .disposed(by: disposeBag)

        viewModel.observableLimit
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.updateUserLimit(with: $0) })
            .disposed(by: disposeBag)

        viewModel.observableNotificationStatus
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.updateNotificationStatus(with: $0) })
            .disposed(by: disposeBag)

        layout.limitTextField.rx.text
            .orEmpty
            .map { UInt($0) ?? 0 }
            .bind(to: viewModel.limit)
            .disposed(by: disposeBag)

        layout.limitButton.action = { [weak self] in
            guard let self = self else { return }
            self.view.endEditing(true)
            self.viewModel.setLimit()
                .subscribe(
                    onCompleted: { [weak self] in self?.notificationFeedback.notificationOccurred(.success) },
                    onError: { [weak self] _ in self?.notificationFeedback.notificationOccurred(.error) }
                )
                .disposed(by: self.disposeBag)
        }

        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] height in
                self?.setBottomInset(height)
            })
            .disposed(by: disposeBag)
    }

    private func updateGasPrice(with state: State.GasPrice) {
        layout.widget.rapid.valueLabel.text = state.rapid
        layout.widget.fast.valueLabel.text = state.fast
        layout.widget.standard.valueLabel.text = state.standard
        layout.widget.slow.valueLabel.text = state.slow
    }

    private func updateUserLimit(with state: State.Limit) {
        layout.limitSync.isSyncing = state.auxiliary.loading
        layout.limitTextField.text = state.limit
        let errorMessage = state.auxiliary.errorMessage
        layout.limitController.setErrorText(errorMessage, errorAccessibilityValue: errorMessage)
        layout.limitButton.isEnabled = !state.auxiliary.loading
    }

    private func updateNotificationStatus(with status: State.NotificationStatus) {
        switch status {
        case .authorized, .notDetermined:
            layout.notificationStatusErrorLabel.isHidden = true
            layout.limitButtonWrapper.isHidden = false
            layout.limitTextField.isHidden = false
        case .denied(let message):
            layout.notificationStatusErrorLabel.isHidden = false
            layout.notificationStatusErrorLabel.text = message
            layout.limitButtonWrapper.isHidden = true
            layout.limitTextField.isHidden = true
        }
    }

    private func setBottomInset(_ keyboardHeight: CGFloat) {
        let trashold = layout.bounds.height - layout.convert(layout.limitButton.frame, from: layout.limitButton).maxY
        let extraInset = keyboardHeight > 0 ? CGFloat.vSpaceMedium : 0
        layout.scrollView.contentInset.bottom = max(0, keyboardHeight - trashold + extraInset)
    }
}
