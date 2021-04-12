import RxSwift
import RxBlocking
import Quick
import Nimble
@testable import Wgii

class GasPriceRepositoryImplTests: QuickSpec { override func spec() {

    describe("#observeGasPrice") {
        it("should emit next loading by default") {
            let repository = gasPriceRepository()

            let state = try repository.observeGasPrice().toBlocking(timeout: 1).first()

            expect(state).to(equal(.loading))
        }

        it("should observe gas price dao") {
            let dao = MockGasPriceDao()
            let repository = gasPriceRepository(dao: dao)


            _ = repository.observeGasPrice()
                .subscribe()

            expect(dao.observeValueCalled).to(beTrue())
        }

        it("should emit next gas price") {
            let gasPrice = GasPrice.zero
            let dao = MockGasPriceDao()
            let repository = gasPriceRepository(dao: dao)

            var emits = [GasPrice.State]()
            _ = repository.observeGasPrice()
                .subscribe(onNext: {
                    emits.append($0)
                })

            dao.listener?(gasPrice)

            let success = GasPrice.State.success(gasPrice)
            expect(emits.last).to(equal(success))
        }

        it("should remove listener on dispose") {
            let listenerHandler = MockListenerHandler()
            let dao = MockGasPriceDao(listenerHandler: listenerHandler)
            let repository = gasPriceRepository(dao: dao)

            let subscription = repository.observeGasPrice()
                .subscribe()

            subscription.dispose()

            expect(dao.removeObserverCalled).to(beTrue())
            expect(dao.removeObserverHandler).to(beIdenticalTo(listenerHandler))
        }

        it("should be shared") {
            let gasPrice = GasPrice.zero
            let dao = MockGasPriceDao()
            let repository = gasPriceRepository(dao: dao)

            var emits1 = [GasPrice.State]()
            _ = repository.observeGasPrice()
                .subscribe(onNext: {
                    emits1.append($0)
                })

            dao.listener?(nil)

            var emits2 = [GasPrice.State]()
            _ = repository.observeGasPrice()
                .subscribe(onNext: {
                    emits2.append($0)
                })

            dao.listener?(gasPrice)

            let success = GasPrice.State.success(gasPrice)
            expect(emits1.last).to(equal(success))
            expect(emits2.last).to(equal(success))
        }

        it("should replay one item") {
            let gasPrice = GasPrice.zero
            let dao = MockGasPriceDao()
            let repository = gasPriceRepository(dao: dao)

            var emits1 = [GasPrice.State]()
            _ = repository.observeGasPrice()
                .subscribe(onNext: {
                    emits1.append($0)
                })

            dao.listener?(gasPrice)

            var emits2 = [GasPrice.State]()
            _ = repository.observeGasPrice()
                .subscribe(onNext: {
                    emits2.append($0)
                })

            let success = GasPrice.State.success(gasPrice)
            expect(emits1.last).to(equal(success))
            expect(emits2.last).to(equal(success))
        }

        it("should clear after last unsubscribe") {
            let dao = MockGasPriceDao()
            let repository = gasPriceRepository(dao: dao)

            let subscription1 = repository.observeGasPrice()
                .subscribe()

            dao.listener?(nil)

            subscription1.dispose()

            var emits2 = [GasPrice.State]()
            _ = repository.observeGasPrice()
                .subscribe(onNext: {
                    emits2.append($0)
                })

            expect(emits2.count).to(equal(1))
            expect(emits2.last).to(equal(.loading))
        }
    }


    func gasPriceRepository(
        dao: GasPriceDao = MockGasPriceDao()
    ) -> GasPriceRepositoryImpl {
        GasPriceRepositoryImpl(dao: dao)
    }

    final class MockListenerHandler {}

    final class MockGasPriceDao: GasPriceDao {
        var observeValueCalled: Bool?
        var removeObserverCalled: Bool?
        var removeObserverHandler: Any?
        var listener: ((GasPrice?) -> Void)?

        let listenerHandler: Any

        init(
            listenerHandler: Any = MockListenerHandler()
        ) {
            self.listenerHandler = listenerHandler
        }

        func observeGasPriceValue(_ listener: @escaping (GasPrice?) -> Void) -> Any {
            observeValueCalled = true
            self.listener = listener
            return listenerHandler
        }

        func removeGasPriceObserver(_ handler: Any) {
            removeObserverCalled = true
            removeObserverHandler = handler
        }
    }
}}
