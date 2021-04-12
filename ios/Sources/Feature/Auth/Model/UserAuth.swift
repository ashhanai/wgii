struct UserAuth: Equatable {
    let uid: String

    enum State {
        case loading
        case success(UserAuth)
    }
}

extension UserAuth.State: Equatable {
    static func == (lhs: UserAuth.State, rhs: UserAuth.State) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading): return true
        case (.success(let lVal), .success(let rVal)): return lVal == rVal
        default: return false
        }
    }
}
