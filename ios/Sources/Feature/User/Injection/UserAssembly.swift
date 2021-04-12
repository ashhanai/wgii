import Swinject
import SwinjectAutoregistration
import FirebaseDatabase

final class UserAssembly: Assembly {

    func assemble(container: Container) {
        container.autoregister(UserUseCase.Observe.self, initializer: UserUseCase.Observe.init)
        container.autoregister(UserUseCase.SetLimit.self, initializer: UserUseCase.SetLimit.init)
        container.autoregister(UserUseCase.SetDeviceToken.self, initializer: UserUseCase.SetDeviceToken.init)

        container.autoregister(UserRepository.self, initializer: UserRepositoryImpl.init)
            .inObjectScope(.container)

        container.register(UserDao.self) { _ in Database.database() }
    }
}
