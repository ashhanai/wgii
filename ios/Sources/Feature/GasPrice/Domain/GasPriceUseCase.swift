import RxSwift

enum GasPriceUseCase {

    final class Observe {
        private let repository: GasPriceRepository

        init(repository: GasPriceRepository) {
            self.repository = repository
        }

        func callAsFunction() -> Observable<GasPrice.State> {
            repository.observeGasPrice()
        }
    }

}
