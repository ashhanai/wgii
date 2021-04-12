import RxSwift
import RxCocoa

final class GasPriceViewModel: ViewModel {
    private let observeGasPrice: GasPriceUseCase.Observe
    private let observeUser: UserUseCase.Observe
    private let setGasLimit: UserUseCase.SetLimit

    lazy var observableGasPrice = observeGasPrice().map(makeGasPriceState)
    lazy var observableLimit = Observable.combineLatest(observeUser(), observableLimitAuxiliary).map(makeUserLimitState)
    lazy var observableNotificationStatus = BehaviorSubject<State.NotificationStatus>(value: .notDetermined)
    let limit = BehaviorSubject<UInt>(value: 1)


    private let observableLimitAuxiliary = BehaviorSubject<State.Auxiliary>(value: State.Auxiliary())
    private let disposeBag = DisposeBag()

    private let numberFormatter = NumberFormatter().apply {
        $0.locale = Locale.current
        $0.usesGroupingSeparator = true
        $0.numberStyle = .decimal
        $0.minimumFractionDigits = 0
    }

    init(
        observeGasPrice: GasPriceUseCase.Observe,
        observeUser: UserUseCase.Observe,
        setGasLimit: UserUseCase.SetLimit
    ) {
        self.observeGasPrice = observeGasPrice
        self.observeUser = observeUser
        self.setGasLimit = setGasLimit

        super.init()

        setup()
    }

    private func setup() {
        observableLimit
            .map { UInt($0.limit) ?? 0 }
            .bind(to: limit)
            .disposed(by: disposeBag)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateNotificationStatus),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        updateNotificationStatus()
    }

    @objc private func updateNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [observableNotificationStatus] settings in
            let message = Localization.Gas.Price.Limit.Notification.denied
            switch settings.authorizationStatus {
            case .authorized, .ephemeral: observableNotificationStatus.onNext(.authorized)
            case .denied, .provisional: observableNotificationStatus.onNext(.denied(message))
            case .notDetermined: observableNotificationStatus.onNext(.notDetermined)
            @unknown default: break
            }
        }
    }

    private func makeGasPriceState(_ model: GasPrice.State) -> State.GasPrice {
        switch model {
        case .loading:
            return State.GasPrice(loading: true)
        case .success(let gasPrice):
            return State.GasPrice(
                rapid: formatPrice(gasPrice.rapid),
                fast: formatPrice(gasPrice.fast),
                standard: formatPrice(gasPrice.standard),
                slow: formatPrice(gasPrice.slow)
            )
        }
    }

    private func formatPrice(_ price: Gwei) -> String {
        numberFormatter.maximumFractionDigits = round(price.gwei) > 0 ? 0 : 2
        return numberFormatter.string(for: price.gwei) ?? "🤔"
    }

    private func makeUserLimitState(_ model: User.State, auxiliary: State.Auxiliary) -> State.Limit {
        switch model {
        case .loading:
            return State.Limit(loading: true)
        case .success(let user):
            return State.Limit(
                loading: auxiliary.loading,
                errorMessage: auxiliary.errorMessage,
                limit: "\(UInt(user.limit.gwei))"
            )
        }
    }
}

extension GasPriceViewModel {
    struct State {
        struct GasPrice {
            let loading: Bool

            let rapid: String
            let fast: String
            let standard: String
            let slow: String

            init(
                loading: Bool = false,
                rapid: String = "...",
                fast: String = "...",
                standard: String = "...",
                slow: String = "..."
            ) {
                self.loading = loading
                self.rapid = rapid
                self.fast = fast
                self.standard = standard
                self.slow = slow
            }
        }

        struct Limit {
            let auxiliary: Auxiliary
            let limit: String

            init(
                loading: Bool = false,
                errorMessage: String? = nil,
                limit: String = ""
            ) {
                self.auxiliary = Auxiliary(
                    loading: loading,
                    errorMessage: errorMessage
                )
                self.limit = limit
            }
        }

        struct Auxiliary {
            let loading: Bool
            let errorMessage: String?

            init(
                loading: Bool = false,
                errorMessage: String? = nil
            ) {
                self.loading = loading
                self.errorMessage = errorMessage
            }
        }

        enum NotificationStatus {
            case authorized
            case notDetermined
            case denied(String)
        }
    }

    func setLimit() -> Completable {
        let observableLimitAuxiliary = self.observableLimitAuxiliary
        do {
            let limitValue = try limit.value()
            observableLimitAuxiliary.onNext(State.Auxiliary(loading: true))
            return setGasLimit(Gwei(gwei: Double(limitValue)))
                .do(
                    onError: { error in
                        observableLimitAuxiliary.onNext(State.Auxiliary(errorMessage: error.localizedDescription))
                    },
                    onCompleted: {
                        observableLimitAuxiliary.onNext(State.Auxiliary())
                    }
                )
        } catch {
            return Completable.error(error)
                .do { error in
                    observableLimitAuxiliary.onNext(State.Auxiliary(errorMessage: error.localizedDescription))
                }
        }
    }
}
