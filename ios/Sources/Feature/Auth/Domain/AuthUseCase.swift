import RxSwift

protocol ObserveAuthUseCase {
    func callAsFunction() -> Observable<UserAuth.State>
}

protocol GetCurrentAuthUseCase {
    func callAsFunction() -> UserAuth?
}

enum AuthUseCase {

    final class Observe: ObserveAuthUseCase {
        private let repository: AuthRepository

        init(repository: AuthRepository) {
            self.repository = repository
        }

        func callAsFunction() -> Observable<UserAuth.State> {
            repository.observeCurrentUser()
                .do { [repository] in
                    if $0 == nil {
                        repository.signInAnonymously()
                    }
                }
                .compactMap { $0 }
        }
    }

    final class GetCurrent: GetCurrentAuthUseCase {
        private let repository: AuthRepository

        init(repository: AuthRepository) {
            self.repository = repository
        }

        func callAsFunction() -> UserAuth? {
            repository.getCurrentUser()
        }
    }

}
