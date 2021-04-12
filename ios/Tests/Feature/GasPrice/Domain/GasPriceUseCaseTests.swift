import RxSwift
import RxBlocking
import Quick
import Nimble
@testable import Wgii

class GasPriceUseCaseTests: QuickSpec { override func spec() {

    describe("#Observe") {
        it("should observe gas price on repository") {
            let repository = MockGasPriceRepository()
            let observe = GasPriceUseCase.Observe(repository: repository)

            _ = observe()

            expect(repository.observeGasPriceCalled).to(beTrue())
        }

        it("should emit next loading") {
            let loading = GasPrice.State.loading
            let repository = MockGasPriceRepository(gasPriceStateObservable: .of(loading))
            let observe = GasPriceUseCase.Observe(repository: repository)

            let last = try observe().toBlocking().last()

            expect(last).to(equal(loading))
        }

        it("should emit next gas price") {
            let gasPrice = GasPrice(
                timestamp: 1,
                rapid: Gwei(gwei: 100),
                fast: Gwei(gwei: 1),
                standard: Gwei(gwei: 14),
                slow: Gwei(gwei: 5.3)
            )
            let success = GasPrice.State.success(gasPrice)
            let repository = MockGasPriceRepository(gasPriceStateObservable: .of(success))
            let observe = GasPriceUseCase.Observe(repository: repository)

            let last = try observe().toBlocking().last()

            expect(last).to(equal(success))
        }
    }


    final class MockGasPriceRepository: GasPriceRepository {
        var observeGasPriceCalled: Bool?

        let gasPriceStateObservable: Observable<GasPrice.State>

        init(
            gasPriceStateObservable: Observable<GasPrice.State> = .just(.loading)
        ) {
            self.gasPriceStateObservable = gasPriceStateObservable
        }

        func observeGasPrice() -> Observable<GasPrice.State> {
            observeGasPriceCalled = true
            return gasPriceStateObservable
        }
    }
}}
