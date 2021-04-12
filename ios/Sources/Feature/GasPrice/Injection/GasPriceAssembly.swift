import Swinject
import SwinjectAutoregistration
import FirebaseDatabase

final class GasPriceAssembly: Assembly {

    func assemble(container: Container) {
        container.autoregister(GasPriceUseCase.Observe.self, initializer: GasPriceUseCase.Observe.init)

        container.autoregister(GasPriceRepository.self, initializer: GasPriceRepositoryImpl.init)
            .inObjectScope(.container)

        container.register(GasPriceDao.self) { _ in Database.database() }

        container.autoregister(GasPriceViewController.self, initializer: GasPriceViewController.init)

        container.autoregister(GasPriceViewModel.self, initializer: GasPriceViewModel.init)
    }
}
