import RxSwift

enum UserError: Error, Equatable {
    case noUserAuth
}

enum UserUseCase {
    final class Observe {
        private let observeAuthUser: ObserveAuthUseCase
        private let userRepository: UserRepository

        init(observeAuthUser: ObserveAuthUseCase, userRepository: UserRepository) {
            self.observeAuthUser = observeAuthUser
            self.userRepository = userRepository
        }

        func callAsFunction() -> Observable<User.State> {
            observeAuthUser()
                .flatMapLatest { [userRepository] userAuthState -> Observable<User.State> in
                    switch userAuthState {
                    case .loading:
                        return .just(.loading)
                    case .success(let userAuth):
                        return userRepository.observeUser(userAuth: userAuth)
                            .map { $0 ?? .success(User(limit: Gwei(wei: 0), auth: userAuth)) }
                    }
                }
        }
    }

    final class SetLimit {
        private let getAuthUser: GetCurrentAuthUseCase
        private let userRepository: UserRepository

        init(getAuthUser: GetCurrentAuthUseCase, userRepository: UserRepository) {
            self.getAuthUser = getAuthUser
            self.userRepository = userRepository
        }

        func callAsFunction(_ limit: Gwei) -> Completable {
            Observable.just(getAuthUser())
                .map {
                    if let userAuth = $0 {
                        return userAuth
                    }
                    throw UserError.noUserAuth
                }
                .flatMapLatest { [userRepository] userAuth in userRepository.setLimit(limit, userAuth: userAuth) }
                .asCompletable()
        }
    }

    final class SetDeviceToken {
        private let getAuthUser: GetCurrentAuthUseCase
        private let userRepository: UserRepository

        init(getAuthUser: GetCurrentAuthUseCase, userRepository: UserRepository) {
            self.getAuthUser = getAuthUser
            self.userRepository = userRepository
        }

        func callAsFunction(_ token: String) -> Completable {
            Observable.just(getAuthUser())
                .map {
                    if let userAuth = $0 {
                        return userAuth
                    }
                    throw UserError.noUserAuth
                }
                .flatMapLatest { [userRepository] userAuth in userRepository.setDeviceToken(token, userAuth: userAuth) }
                .asCompletable()
        }
    }
}
