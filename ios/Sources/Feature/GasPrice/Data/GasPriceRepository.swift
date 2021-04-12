import FirebaseDatabase
import RxSwift

protocol GasPriceRepository {
    func observeGasPrice() -> Observable<GasPrice.State>
}

final class GasPriceRepositoryImpl {
    private let dao: GasPriceDao

    private lazy var _observeGasPrice = Observable<GasPrice.State>.create { [dao] observer -> Disposable in
        observer.onNext(.loading)
        let handler = dao.observeGasPriceValue { gasPrice in
            if let gasPrice = gasPrice {
                observer.onNext(.success(gasPrice))
            }
        }

        return Disposables.create {
            dao.removeGasPriceObserver(handler)
        }
    }.share(replay: 1)

    init(dao: GasPriceDao) {
        self.dao = dao
    }
}

extension GasPriceRepositoryImpl: GasPriceRepository {
    func observeGasPrice() -> Observable<GasPrice.State> {
        _observeGasPrice
    }
}
