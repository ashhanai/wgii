import RxSwift
import RxBlocking
import RxTest
import Quick
import Nimble
@testable import Wgii

class UserRepositoryImplTests: QuickSpec { override func spec() {

    describe("#observeUser") {
        it("should emit next loading by default") {
            let userAuth = UserAuth(uid: "uid")
            let repository = userRepository()

            let state = try repository.observeUser(userAuth: userAuth).toBlocking(timeout: 1).first()

            expect(state).to(equal(.loading))
        }

        it("should observe user dao") {
            let userAuth = UserAuth(uid: "uid")
            let dao = MockUserDao()
            let repository = userRepository(dao: dao)


            _ = repository.observeUser(userAuth: userAuth)
                .subscribe()

            expect(dao.observeValueCalled).to(beTrue())
        }

        it("should emit next user") {
            let userAuth = UserAuth(uid: "uid")
            let user = User(limit: Gwei(gwei: 100), auth: userAuth)
            let dao = MockUserDao()
            let repository = userRepository(dao: dao)

            var emits = [User.State?]()
            _ = repository.observeUser(userAuth: userAuth)
                .subscribe(onNext: {
                    emits.append($0)
                })

            dao.listener?(user)

            let success = User.State.success(user)
            expect(emits.last).to(equal(success))
        }

        it("should emit next nil") {
            let userAuth = UserAuth(uid: "uid")
            let dao = MockUserDao()
            let repository = userRepository(dao: dao)

            var emittedState: User.State?
            _ = repository.observeUser(userAuth: userAuth)
                .subscribe(onNext: {
                    emittedState = $0
                })

            dao.listener?(nil)

            expect(emittedState).to(beNil())
        }

        it("should remove listener on dispose") {
            let userAuth = UserAuth(uid: "uid")
            let listenerHandler = MockListenerHandler()
            let dao = MockUserDao(listenerHandler: listenerHandler)
            let repository = userRepository(dao: dao)

            let subscription = repository.observeUser(userAuth: userAuth)
                .subscribe()

            subscription.dispose()

            expect(dao.removeObserverCalled).to(beTrue())
            expect(dao.removeObserverHandler).to(beIdenticalTo(listenerHandler))
        }

        it("should be shared") {
            let userAuth = UserAuth(uid: "uid")
            let user = User(limit: Gwei(gwei: 100), auth: userAuth)
            let dao = MockUserDao()
            let repository = userRepository(dao: dao)

            var emits1 = [User.State?]()
            _ = repository.observeUser(userAuth: userAuth)
                .subscribe(onNext: {
                    emits1.append($0)
                })

            dao.listener?(nil)

            var emits2 = [User.State?]()
            _ = repository.observeUser(userAuth: userAuth)
                .subscribe(onNext: {
                    emits2.append($0)
                })

            dao.listener?(user)

            let success = User.State.success(user)
            expect(emits1.last).to(equal(success))
            expect(emits2.last).to(equal(success))
        }

        it("should replay one item") {
            let userAuth = UserAuth(uid: "uid")
            let user = User(limit: Gwei(gwei: 100), auth: userAuth)
            let dao = MockUserDao()
            let repository = userRepository(dao: dao)

            var emits1 = [User.State?]()
            _ = repository.observeUser(userAuth: userAuth)
                .subscribe(onNext: {
                    emits1.append($0)
                })

            dao.listener?(user)

            var emits2 = [User.State?]()
            _ = repository.observeUser(userAuth: userAuth)
                .subscribe(onNext: {
                    emits2.append($0)
                })

            let success = User.State.success(user)
            expect(emits1.last).to(equal(success))
            expect(emits2.last).to(equal(success))        }

        it("should clear after last unsubscribe") {
            let userAuth = UserAuth(uid: "uid")
            let dao = MockUserDao()
            let repository = userRepository(dao: dao)

            let subscription1 = repository.observeUser(userAuth: userAuth)
                .subscribe()

            dao.listener?(nil)

            subscription1.dispose()

            var emits2 = [User.State?]()
            _ = repository.observeUser(userAuth: userAuth)
                .subscribe(onNext: {
                    emits2.append($0)
                })

            expect(emits2.count).to(equal(1))
            expect(emits2.last).to(equal(.loading))
        }
    }

    describe("#setLimit") {
        it("should set limit on dao") {
            let userAuth = UserAuth(uid: "uid")
            let dao = MockUserDao()
            let repository = userRepository(dao: dao)

            _ = repository.setLimit(Gwei(gwei: 100), userAuth: userAuth)
                .toBlocking(timeout: 1).materialize()

            expect(dao.setLimitCalled).to(beTrue())
            expect(dao.limit?.gwei).to(equal(100))
            expect(dao.userAuth?.uid).to(equal("uid"))
        }

        it("should complete on success") {
            let userAuth = UserAuth(uid: "uid")
            let dao = MockUserDao()
            let repository = userRepository(dao: dao)

            var event: CompletableEvent?
            _ = repository.setLimit(Gwei(gwei: 100), userAuth: userAuth)
                .subscribe {
                    event = $0
                }

            dao.callback?(.success(()))

            expect(event).to(equal(.completed))
        }

        it("should fail on error") {
            let userAuth = UserAuth(uid: "uid")
            let dao = MockUserDao()
            let repository = userRepository(dao: dao)

            var event: CompletableEvent?
            _ = repository.setLimit(Gwei(gwei: 100), userAuth: userAuth)
                .subscribe {
                    event = $0
                }

            dao.callback?(.failure(DummyError()))

            let error = CompletableEvent.error(DummyError())
            expect(event).to(equal(error))
        }
    }

    describe("#setDeviceToken") {
        it("should set device token on dao") {
            let userAuth = UserAuth(uid: "uid")
            let dao = MockUserDao()
            let repository = userRepository(dao: dao)

            _ = repository.setDeviceToken("token", userAuth: userAuth)
                .toBlocking(timeout: 1).materialize()

            expect(dao.setDeviceTokenCalled).to(beTrue())
            expect(dao.token).to(equal("token"))
            expect(dao.userAuth?.uid).to(equal("uid"))
        }

        it("should complete on success") {
            let userAuth = UserAuth(uid: "uid")
            let dao = MockUserDao()
            let repository = userRepository(dao: dao)

            var event: CompletableEvent?
            _ = repository.setDeviceToken("token", userAuth: userAuth)
                .subscribe {
                    event = $0
                }

            dao.callback?(.success(()))

            expect(event).to(equal(.completed))
        }

        it("should fail on error") {
            let userAuth = UserAuth(uid: "uid")
            let dao = MockUserDao()
            let repository = userRepository(dao: dao)

            var event: CompletableEvent?
            _ = repository.setDeviceToken("token", userAuth: userAuth)
                .subscribe {
                    event = $0
                }

            dao.callback?(.failure(DummyError()))

            let error = CompletableEvent.error(DummyError())
            expect(event).to(equal(error))
        }
    }


    func userRepository(
        dao: UserDao = MockUserDao()
    ) -> UserRepositoryImpl {
        UserRepositoryImpl(dao: dao)
    }

    final class DummyError: Error {}

    final class MockListenerHandler {}

    final class MockUserDao: UserDao {
        var observeValueCalled: Bool?
        var setLimitCalled: Bool?
        var removeObserverCalled: Bool?
        var setDeviceTokenCalled: Bool?
        var removeObserverHandler: Any?
        var listener: ((User?) -> Void)?
        var callback: ((Result<Void, Error>) -> Void)?
        var userAuth: UserAuth?
        var limit: Gwei?
        var token: String?

        let listenerHandler: Any

        init(
            listenerHandler: Any = MockListenerHandler()
        ) {
            self.listenerHandler = listenerHandler
        }

        func observeUserValue(userAuth: UserAuth, listener: @escaping (User?) -> Void) -> Any {
            observeValueCalled = true
            self.listener = listener
            self.userAuth = userAuth
            return listenerHandler
        }

        func removeUserObserver(_ handler: Any) {
            removeObserverCalled = true
            removeObserverHandler = handler
        }

        func setLimit(_ limit: Gwei, userAuth: UserAuth, callback: @escaping (Result<Void, Error>) -> Void) {
            setLimitCalled = true
            self.limit = limit
            self.userAuth = userAuth
            self.callback = callback
        }

        func setDeviceToken(_ token: String, userAuth: UserAuth, callback: @escaping (Result<Void, Error>) -> Void) {
            setDeviceTokenCalled = true
            self.token = token
            self.userAuth = userAuth
            self.callback = callback
        }
    }

}}
