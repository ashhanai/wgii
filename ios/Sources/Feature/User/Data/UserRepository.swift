import RxSwift

protocol UserRepository {
    func observeUser(userAuth: UserAuth) -> Observable<User.State?>
    func setLimit(_ limit: Gwei, userAuth: UserAuth) -> Completable
    func setDeviceToken(_ token: String, userAuth: UserAuth) -> Completable
}

final class UserRepositoryImpl {
    private let dao: UserDao

    private var _observeUserDic = [String: Observable<User.State?>]()

    init(dao: UserDao) {
        self.dao = dao
    }
}

extension UserRepositoryImpl: UserRepository {
    func observeUser(userAuth: UserAuth) -> Observable<User.State?> {
        if let observeUser = _observeUserDic[userAuth.uid] {
            return observeUser
        }

        let observeUser = Observable<User.State?>.create { [dao] observer -> Disposable in
            observer.onNext(.loading)
            let handler = dao.observeUserValue(userAuth: userAuth) { user in
                if let user = user {
                    observer.onNext(.success(user))
                } else {
                    observer.onNext(nil)
                }
            }

            return Disposables.create {
                dao.removeUserObserver(handler)
            }
        }.share(replay: 1)

        _observeUserDic[userAuth.uid] = observeUser
        return observeUser
    }

    func setLimit(_ limit: Gwei, userAuth: UserAuth) -> Completable {
        Completable.create { [dao] completable in
            dao.setLimit(limit, userAuth: userAuth) { result in
                switch result {
                case .success:
                    completable(.completed)
                case .failure(let error):
                    completable(.error(error))
                }
            }

            return Disposables.create()
        }
    }

    func setDeviceToken(_ token: String, userAuth: UserAuth) -> Completable {
        Completable.create { [dao] completable in
            dao.setDeviceToken(token, userAuth: userAuth) { result in
                switch result {
                case .success:
                    completable(.completed)
                case .failure(let error):
                    completable(.error(error))
                }
            }

            return Disposables.create()
        }
    }
}
