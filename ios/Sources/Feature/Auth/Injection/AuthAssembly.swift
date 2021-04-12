import Swinject
import SwinjectAutoregistration
import FirebaseAuth

final class AuthAssembly: Assembly {

    func assemble(container: Container) {
        container.autoregister(ObserveAuthUseCase.self, initializer: AuthUseCase.Observe.init)
        container.autoregister(GetCurrentAuthUseCase.self, initializer: AuthUseCase.GetCurrent.init)

        container.autoregister(AuthRepository.self, initializer: AuthRepositoryImpl.init)
            .inObjectScope(.container)

        container.register(AuthDao.self) { _ in Auth.auth() }
    }
}
