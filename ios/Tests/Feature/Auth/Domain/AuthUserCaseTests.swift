import RxSwift
import RxBlocking
import Quick
import Nimble
@testable import Wgii

class AuthUseCaseTests: QuickSpec { override func spec() {

    describe("#Observe") {
        it("should observe current user on repository") {
            let repository = MockAuthRepository()
            let observe = AuthUseCase.Observe(repository: repository)

            _ = observe()

            expect(repository.isObserveCurrentUserCalled).to(beTrue())
        }

        it("should emit next loading") {
            let loading = UserAuth.State.loading
            let repository = MockAuthRepository(userAuthStateObservable: .of(loading))
            let observe = AuthUseCase.Observe(repository: repository)

            let last = try observe().toBlocking().last()

            expect(last).to(equal(loading))
        }

        it("should emit next user auth") {
            let success = UserAuth.State.success(UserAuth(uid: "test_uid"))
            let repository = MockAuthRepository(userAuthStateObservable: .of(success))
            let observe = AuthUseCase.Observe(repository: repository)

            let last = try observe().toBlocking().last()

            expect(last).to(equal(success))
        }

        it("should not emit nil") {
            let repository = MockAuthRepository(userAuthStateObservable: .of(nil))
            let observe = AuthUseCase.Observe(repository: repository)

            let sequence = try observe().toBlocking().toArray()

            expect(sequence).to(beEmpty())
        }

        it("should call sign in when emitting nil") {
            let repository = MockAuthRepository(userAuthStateObservable: .of(nil))
            let observe = AuthUseCase.Observe(repository: repository)

            _ = try observe().toBlocking().last()

            expect(repository.isSignInAnonymouslyCalled).to(beTrue())
        }
    }

    describe("#Get") {
        it("should get current user from repository") {
            let uid = "test_uid"
            let repository = MockAuthRepository(currentUser: UserAuth(uid: uid))
            let get = AuthUseCase.GetCurrent(repository: repository)

            let userAuth = get()

            expect(userAuth?.uid).to(equal(uid))
        }

        it("should get empty current auth user") {
            let repository = MockAuthRepository(currentUser: nil)
            let get = AuthUseCase.GetCurrent(repository: repository)

            let userAuth = get()

            expect(userAuth).to(beNil())
        }
    }


    final class MockAuthRepository: AuthRepository {
        var isObserveCurrentUserCalled: Bool?
        var isSignInAnonymouslyCalled: Bool?
        var isGetCurrentUserCalled: Bool?

        let userAuthStateObservable: Observable<UserAuth.State?>
        let currentUser: UserAuth?

        init(
            userAuthStateObservable: Observable<UserAuth.State?> = .just(.loading),
            currentUser: UserAuth? = nil
        ) {
            self.userAuthStateObservable = userAuthStateObservable
            self.currentUser = currentUser
        }

        func observeCurrentUser() -> Observable<UserAuth.State?> {
            isObserveCurrentUserCalled = true
            return userAuthStateObservable
        }

        func getCurrentUser() -> UserAuth? {
            isGetCurrentUserCalled = true
            return currentUser
        }

        func signInAnonymously() {
            isSignInAnonymouslyCalled = true
        }
    }
}}
