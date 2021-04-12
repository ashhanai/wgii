import RxSwift
import RxBlocking
import RxTest
import Quick
import Nimble
@testable import Wgii

class UserUseCaseTests: QuickSpec { override func spec() {

    describe("#Observe") {
        it("should observe auth user") {
            let observeAuthUser = MockObserveAuthUseCase()
            let observe = observeUseCase(observeAuthUser: observeAuthUser)

            _ = observe().toBlocking(timeout: 1).materialize()

            expect(observeAuthUser.called).to(beTrue())
        }

        it("should map loading to user state") {
            let observeAuthUser = MockObserveAuthUseCase(observable: .just(.loading))
            let observe = observeUseCase(observeAuthUser: observeAuthUser)

            let lastEmit = try observe().toBlocking(timeout: 1).last()

            expect(lastEmit).to(equal(User.State.loading))
        }

        it("should observe user on repository on success and pass user auth") {
            let userAuth = UserAuth(uid: "uid")
            let observeAuthUser = MockObserveAuthUseCase(observable: .just(.success(userAuth)))
            let repository = MockUserRepository()
            let observe = observeUseCase(observeAuthUser: observeAuthUser, userRepository: repository)

            _ = observe().toBlocking(timeout: 1).materialize()

            expect(repository.observeUserCalled).to(beTrue())
        }

        it("should emit success from user repository") {
            let userAuth = UserAuth(uid: "uid")
            let observeAuthUser = MockObserveAuthUseCase(observable: .just(.success(userAuth)))
            let user = User(limit: Gwei(gwei: 100), auth: userAuth)
            let repository = MockUserRepository(userObservable: .just(.success(user)))
            let observe = observeUseCase(observeAuthUser: observeAuthUser, userRepository: repository)

            let lastEmit = try observe().toBlocking(timeout: 1).last()

            let success = User.State.success(user)
            expect(lastEmit).to(equal(success))
        }

        it("should emit default user when nil from user repository") {
            let userAuth = UserAuth(uid: "uid")
            let observeAuthUser = MockObserveAuthUseCase(observable: .just(.success(userAuth)))
            let repository = MockUserRepository(userObservable: .just(nil))
            let observe = observeUseCase(observeAuthUser: observeAuthUser, userRepository: repository)

            let lastEmit = try observe().toBlocking(timeout: 1).last()

            let success = User.State.success(User(limit: Gwei(gwei: 0), auth: userAuth))
            expect(lastEmit).to(equal(success))
        }
    }

    describe("#SetLimit") {
        it("should get auth user") {
            let getCurrentAuthUser = MockGetCurrentAuthUseCase(userAuth: nil)
            let setLimit = setLimitUseCase(getAuthUser: getCurrentAuthUser)

            _ = setLimit(Gwei(gwei: 100)).toBlocking(timeout: 1)

            expect(getCurrentAuthUser.called).to(beTrue())
        }

        it("should fail if there is no auth user") {
            let getCurrentAuthUser = MockGetCurrentAuthUseCase(userAuth: nil)
            let setLimit = setLimitUseCase(getAuthUser: getCurrentAuthUser)

            let result = setLimit(Gwei(gwei: 100)).toBlocking(timeout: 1).materialize()

            guard case .failed(_ , let error) = result else { fail(); return }

            expect(error).to(matchError(UserError.noUserAuth))
        }

        it("should call set limit on repository") {
            let userAuth = UserAuth(uid: "uid_123")
            let getCurrentAuthUser = MockGetCurrentAuthUseCase(userAuth: userAuth)
            let repository = MockUserRepository()
            let setLimit = setLimitUseCase(getAuthUser: getCurrentAuthUser, userRepository: repository)

            _ = setLimit(Gwei(gwei: 100)).toBlocking(timeout: 1).materialize()

            expect(repository.setLimitCalled).to(beTrue())
            expect(repository.limit?.gwei).to(equal(100))
            expect(repository.userAuth?.uid).to(beIdenticalTo(userAuth.uid))
        }

        it("should emit success and complete") {
            let repository = MockUserRepository(
                setLimitCompletable: Completable.create { $0(.completed); return Disposables.create() }
            )
            let setLimit = setLimitUseCase(userRepository: repository)

            let result = setLimit(Gwei(gwei: 100)).toBlocking(timeout: 1).materialize()

            guard case .completed = result else { fail(); return }
        }

        it("should emit failure") {
            let dummyError = DummyError()
            let repository = MockUserRepository(
                setLimitCompletable: Completable.create { $0(.error(dummyError)); return Disposables.create() }
            )
            let setLimit = setLimitUseCase(userRepository: repository)

            let result = setLimit(Gwei(gwei: 100)).toBlocking(timeout: 1).materialize()

            guard case .failed(_, let error) = result else { fail(); return }

            expect(error).to(beIdenticalTo(dummyError))
        }
    }

    describe("#SetDeviceToken") {
        it("should get auth user") {
            let getCurrentAuthUser = MockGetCurrentAuthUseCase(userAuth: nil)
            let setDeviceToken = setDeviceTokenUseCase(getAuthUser: getCurrentAuthUser)

            _ = setDeviceToken("token").toBlocking(timeout: 1)

            expect(getCurrentAuthUser.called).to(beTrue())
        }

        it("should fail if there is no auth user") {
            let getCurrentAuthUser = MockGetCurrentAuthUseCase(userAuth: nil)
            let setDeviceToken = setDeviceTokenUseCase(getAuthUser: getCurrentAuthUser)

            let result = setDeviceToken("token").toBlocking(timeout: 1).materialize()

            guard case .failed(_ , let error) = result else { fail(); return }

            expect(error).to(matchError(UserError.noUserAuth))
        }

        it("should call set device token on repository") {
            let userAuth = UserAuth(uid: "uid_123")
            let getCurrentAuthUser = MockGetCurrentAuthUseCase(userAuth: userAuth)
            let repository = MockUserRepository()
            let setDeviceToken = setDeviceTokenUseCase(getAuthUser: getCurrentAuthUser, userRepository: repository)

            _ = setDeviceToken("token").toBlocking(timeout: 1).materialize()

            expect(repository.setDeviceTokenCalled).to(beTrue())
            expect(repository.token).to(equal("token"))
            expect(repository.userAuth?.uid).to(beIdenticalTo(userAuth.uid))
        }

        it("should emit success and complete") {
            let repository = MockUserRepository(
                setDeviceTokenCompletable: Completable.create { $0(.completed); return Disposables.create() }
            )
            let setDeviceToken = setDeviceTokenUseCase(userRepository: repository)

            let result = setDeviceToken("token").toBlocking(timeout: 1).materialize()

            guard case .completed = result else { fail(); return }
        }

        it("should emit failure") {
            let dummyError = DummyError()
            let repository = MockUserRepository(
                setDeviceTokenCompletable: Completable.create { $0(.error(dummyError)); return Disposables.create() }
            )
            let setDeviceToken = setDeviceTokenUseCase(userRepository: repository)

            let result = setDeviceToken("token").toBlocking(timeout: 1).materialize()

            guard case .failed(_, let error) = result else { fail(); return }

            expect(error).to(beIdenticalTo(dummyError))
        }
    }


    func observeUseCase(
        observeAuthUser: MockObserveAuthUseCase = MockObserveAuthUseCase(),
        userRepository: MockUserRepository = MockUserRepository()
    ) -> UserUseCase.Observe {
        UserUseCase.Observe(
            observeAuthUser: observeAuthUser,
            userRepository: userRepository
        )
    }

    func setLimitUseCase(
        getAuthUser: MockGetCurrentAuthUseCase = MockGetCurrentAuthUseCase(),
        userRepository: MockUserRepository = MockUserRepository()
    ) -> UserUseCase.SetLimit {
        UserUseCase.SetLimit(
            getAuthUser: getAuthUser,
            userRepository: userRepository
        )
    }

    func setDeviceTokenUseCase(
        getAuthUser: MockGetCurrentAuthUseCase = MockGetCurrentAuthUseCase(),
        userRepository: MockUserRepository = MockUserRepository()
    ) -> UserUseCase.SetDeviceToken {
        UserUseCase.SetDeviceToken(
            getAuthUser: getAuthUser,
            userRepository: userRepository
        )
    }

    final class DummyError: Error {}

    final class MockObserveAuthUseCase: ObserveAuthUseCase {
        var called: Bool?

        let observable: Observable<UserAuth.State>

        init(observable: Observable<UserAuth.State> = .just(.loading)) {
            self.observable = observable
        }

        func callAsFunction() -> Observable<UserAuth.State> {
            called = true
            return observable
        }
    }

    final class MockGetCurrentAuthUseCase: GetCurrentAuthUseCase {
        var called: Bool?

        let userAuth: UserAuth?

        init(userAuth: UserAuth? = UserAuth(uid: "uid")) {
            self.userAuth = userAuth
        }

        func callAsFunction() -> UserAuth? {
            called = true
            return userAuth
        }
    }

    final class MockUserRepository: UserRepository {
        var observeUserCalled: Bool?
        var setLimitCalled: Bool?
        var setDeviceTokenCalled: Bool?
        var userAuth: UserAuth?
        var limit: Gwei?
        var token: String?

        let userObservable: Observable<User.State?>
        let setLimitCompletable: Completable
        let setDeviceTokenCompletable: Completable

        init(
            userObservable: Observable<User.State?> = .just(.loading),
            setLimitCompletable: Completable = Observable.never().asCompletable(),
            setDeviceTokenCompletable: Completable = Observable.never().asCompletable()
        ) {
            self.userObservable = userObservable
            self.setLimitCompletable = setLimitCompletable
            self.setDeviceTokenCompletable = setDeviceTokenCompletable
        }

        func observeUser(userAuth: UserAuth) -> Observable<User.State?> {
            observeUserCalled = true
            self.userAuth = userAuth
            return userObservable
        }

        func setLimit(_ limit: Gwei, userAuth: UserAuth) -> Completable {
            setLimitCalled = true
            self.limit = limit
            self.userAuth = userAuth
            return setLimitCompletable
        }

        func setDeviceToken(_ token: String, userAuth: UserAuth) -> Completable {
            setDeviceTokenCalled = true
            self.token = token
            self.userAuth = userAuth
            return setDeviceTokenCompletable
        }
    }
}}
