import RxSwift

protocol AuthRepository {
    func observeCurrentUser() -> Observable<UserAuth.State?>
    func getCurrentUser() -> UserAuth?
    func signInAnonymously()
}

final class AuthRepositoryImpl {
    private let dao: AuthDao
    private lazy var _currentUserObserver = Observable<UserAuth.State?>.create { [dao] observer -> Disposable in
        observer.onNext(.loading)
        let handler = dao.addStateDidChangeListener { userAuth in
            if let userAuth = userAuth {
                observer.onNext(.success(userAuth))
            } else {
                observer.onNext(nil)
            }
        }

        return Disposables.create {
            dao.removeStateDidChangeListener(handler)
        }
    }.share(replay: 1)

    init(dao: AuthDao) {
        self.dao = dao
    }
}

extension AuthRepositoryImpl: AuthRepository {
    func observeCurrentUser() -> Observable<UserAuth.State?> {
        _currentUserObserver
    }

    func getCurrentUser() -> UserAuth? {
        dao.currentUser()
    }

    func signInAnonymously() {
        dao.signInAnonymously()
    }
}
