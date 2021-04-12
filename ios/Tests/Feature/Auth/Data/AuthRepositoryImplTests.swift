import RxSwift
import RxBlocking
import Quick
import Nimble
@testable import Wgii

class AuthRepositoryImplTests: QuickSpec { override func spec() {

    describe("#observeCurrentUser") {
        it("should emit next loading by default") {
            let repository = authRepository()

            let state = try repository.observeCurrentUser().toBlocking(timeout: 1).first()

            expect(state).to(equal(.loading))
        }

        it("should emit next user auth") {
            let userAuth = UserAuth(uid: "uid_321")
            let dao = MockAuthDao()
            let repository = authRepository(dao: dao)

            var emittedState: UserAuth.State?
            _ = repository.observeCurrentUser()
                .subscribe(onNext: {
                    emittedState = $0
                })

            dao.listener?(userAuth)

            let success = UserAuth.State.success(userAuth)
            expect(emittedState).to(equal(success))
        }

        it("should emit next nil") {
            let dao = MockAuthDao()
            let repository = authRepository(dao: dao)

            var emittedState: UserAuth.State?
            _ = repository.observeCurrentUser()
                .subscribe(onNext: {
                    emittedState = $0
                })

            dao.listener?(nil)

            expect(emittedState).to(beNil())
        }

        it("should remove listener on dispose") {
            let listenerHandler = MockListenerHandler()
            let dao = MockAuthDao(listenerHandler: listenerHandler)
            let repository = authRepository(dao: dao)

            let subscription = repository.observeCurrentUser()
                .subscribe()

            subscription.dispose()

            expect(dao.removeStateDidChangeListenerCalled).to(beTrue())
            expect(dao.removeStateDidChangeListenerHandler).to(beIdenticalTo(listenerHandler))
        }

        it("should be shared") {
            let userAuth = UserAuth(uid: "test_uid")
            let dao = MockAuthDao()
            let repository = authRepository(dao: dao)

            var emittedStates1 = [UserAuth.State?]()
            _ = repository.observeCurrentUser()
                .subscribe(onNext: {
                    emittedStates1.append($0)
                })

            dao.listener?(nil)

            var emittedStates2 = [UserAuth.State?]()
            _ = repository.observeCurrentUser()
                .subscribe(onNext: {
                    emittedStates2.append($0)
                })

            dao.listener?(userAuth)

            let success = UserAuth.State.success(userAuth)
            expect(emittedStates1.last).to(equal(success))
            expect(emittedStates2.last).to(equal(success))
        }

        it("should replay one item") {
            let dao = MockAuthDao()
            let repository = authRepository(dao: dao)

            var emittedStates1 = [UserAuth.State?]()
            _ = repository.observeCurrentUser()
                .subscribe(onNext: {
                    emittedStates1.append($0)
                })

            let userAuth = UserAuth(uid: "uid")
            dao.listener?(userAuth)

            var emittedStates2 = [UserAuth.State?]()
            _ = repository.observeCurrentUser()
                .subscribe(onNext: {
                    emittedStates2.append($0)
                })

            let success = UserAuth.State.success(userAuth)
            expect(emittedStates1.last).to(equal(success))
            expect(emittedStates2.last).to(equal(success))
        }

        it("should clear after last unsubscribe") {
            let dao = MockAuthDao()
            let repository = authRepository(dao: dao)

            let subscription1 = repository.observeCurrentUser()
                .subscribe()

            let userAuth = UserAuth(uid: "uid")
            dao.listener?(userAuth)

            subscription1.dispose()

            var emittedStates2 = [UserAuth.State?]()
            _ = repository.observeCurrentUser()
                .subscribe(onNext: {
                    emittedStates2.append($0)
                })

            expect(emittedStates2.count).to(equal(1))
            expect(emittedStates2.last).to(equal(.loading))
        }
    }

    describe("#getCurrentUser") {
        it("should get user auth from dao") {
            let userAuth = UserAuth(uid: "uid_123")
            let dao = MockAuthDao(userAuth: userAuth)
            let repository = authRepository(dao: dao)

            let currentUser = repository.getCurrentUser()

            expect(dao.currentUserCalled).to(beTrue())
            expect(currentUser).toNot(beNil())
            expect(currentUser?.uid).to(equal(userAuth.uid))
        }

        it("should get nil from dao") {
            let dao = MockAuthDao(userAuth: nil)
            let repository = authRepository(dao: dao)

            let currentUser = repository.getCurrentUser()

            expect(dao.currentUserCalled).to(beTrue())
            expect(currentUser).to(beNil())
        }
    }

    describe("#signInAnonymously") {
        it("should call sing in anonymously on dao") {
            let dao = MockAuthDao()
            let repository = authRepository(dao: dao)

            repository.signInAnonymously()

            expect(dao.signInAnonymouslyCalled).to(beTrue())
        }
    }


    func authRepository(
        dao: AuthDao = MockAuthDao()
    ) -> AuthRepositoryImpl {
        AuthRepositoryImpl(dao: dao)
    }

    final class MockListenerHandler {}

    final class MockAuthDao: AuthDao {
        var currentUserCalled: Bool?
        var addStateDidChangeListenerCalled: Bool?
        var removeStateDidChangeListenerCalled: Bool?
        var signInAnonymouslyCalled: Bool?
        var removeStateDidChangeListenerHandler: Any?
        var listener: ((UserAuth?) -> Void)?

        let userAuth: UserAuth?
        let listenerHandler: Any

        init(
            userAuth: UserAuth? = nil,
            listenerHandler: Any = MockListenerHandler()
        ) {
            self.userAuth = userAuth
            self.listenerHandler = listenerHandler
        }

        func currentUser() -> UserAuth? {
            currentUserCalled = true
            return userAuth
        }

        func addStateDidChangeListener(_ listener: @escaping (UserAuth?) -> Void) -> Any {
            addStateDidChangeListenerCalled = true
            self.listener = listener
            return listenerHandler
        }

        func removeStateDidChangeListener(_ handler: Any) {
            removeStateDidChangeListenerCalled = true
            removeStateDidChangeListenerHandler = handler
        }

        func signInAnonymously() {
            signInAnonymouslyCalled = true
        }
    }
}}
